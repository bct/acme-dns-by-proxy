# based on https://github.com/NixOS/nixpkgs/blob/master/nixos/tests/acme/dns01.nix
#
# This test validates that the acme-dns-by-proxy client & host modules work together.
# There are 3 hosts here:
#
# - "acme" is an ACME server that can provide a certificate.
# - "dnsserver" hosts a DNS server, and an acme-dns-proxy.
#   the acme-dns-proxy is able to add & remove records from the DNS server.
# - "client" is attempting to obtain a certificate from "acme".
#   to do this it needs to use the proxy to add a record to the DNS server.
#
# The test passes if "client" successfully obtains a certificate.
{
  self,
  pkgs,
  nixpkgs,
}:
let
  lib = pkgs.lib;

  domain = "authorized-subdomain.example.org";

  dnsServerIP = nodes: nodes.dnsserver.networking.primaryIPAddress;

  dnsScript = pkgs.writeShellScript "dns-hook.sh" ''
    set -euo pipefail
    echo '[INFO]' "[$2]" 'dns-hook.sh' $*
    if [ "$1" = "present" ]; then
      ${pkgs.curl}/bin/curl --data @- http://localhost:8055/set-txt << EOF
      {"host": "$2", "value": "$3"}
    EOF
    else
      ${pkgs.curl}/bin/curl --data @- http://localhost:8055/clear-txt << EOF
      {"host": "$2"}
    EOF
    fi
  '';

  inherit (import ./ssh-keys.nix pkgs)
    snakeOilPrivateKey
    snakeOilPublicKey
    hostPrivateKey
    hostPublicKey
    ;
in
{
  name = "acme-dns-proxy-e2e";

  meta = {
    # Hard timeout in seconds. Average run time is about 60 seconds.
    timeout = 180;
  };

  nodes = {
    # The fake ACME server which will respond to client requests
    acme =
      { nodes, ... }:
      {
        imports = [ "${nixpkgs}/nixos/tests/common/acme/server" ];
        networking.nameservers = lib.mkForce [ (dnsServerIP nodes) ];
      };

    # A host that runs a DNS server and the acme-dns-proxy.
    # DNS-01 challenge records can be created using the proxy.
    dnsserver =
      { nodes, ... }:
      {
        imports = [ self.nixosModules.host ];

        networking = {
          firewall.allowedTCPPorts = [
            22
            53
          ];
          firewall.allowedUDPPorts = [ 53 ];

          # nixos/lib/testing/network.nix will provide name resolution via /etc/hosts
          # for all nodes based on their host names and domain
          hostName = "dnsserver";
          domain = "test";
        };

        services.openssh = {
          hostKeys = [ ];
          extraConfig = "HostKey /run/ssh_host_key";
        };
        system.activationScripts.install-ssh-host-key = ''
          cat ${hostPrivateKey} >/run/ssh_host_key
          chmod 0600 /run/ssh_host_key
        '';

        services.acme-dns-proxy-host = {
          enable = true;
          domains = [
            {
              domain = domain;
              execCommand = dnsScript;
              pubKey = snakeOilPublicKey;
            }
          ];
        };

        systemd.services.pebble-challtestsrv = {
          enable = true;
          description = "Pebble ACME challenge test server";
          wantedBy = [ "network.target" ];
          serviceConfig = {
            ExecStart = "${pkgs.pebble}/bin/pebble-challtestsrv -dns01 ':53' -defaultIPv6 '' -defaultIPv4 '${nodes.client.networking.primaryIPAddress}'";
            # Required to bind on privileged ports.
            AmbientCapabilities = [ "CAP_NET_BIND_SERVICE" ];
          };
        };
      };

    client =
      { nodes, ... }:
      {
        imports = [
          "${nixpkgs}/nixos/tests/common/acme/client"
          self.nixosModules.client
        ];

        networking.domain = domain;
        networking.nameservers = lib.mkForce [ (dnsServerIP nodes) ];

        # OpenSSL will be used for more thorough certificate validation
        environment.systemPackages = [ pkgs.openssl ];

        security.acme.certs."${domain}" = {
          dnsPropagationCheck = false;
          environmentFile = pkgs.writeText "acme-exec-env" ''
            EXEC_POLLING_INTERVAL=1
            EXEC_PROPAGATION_TIMEOUT=1
            EXEC_SEQUENCE_INTERVAL=1
          '';
        };
        security.acme.dnsChallengeProxies."${domain}" = {
          host = "dnsserver.test";
          sshIdentity = toString snakeOilPrivateKey;
          hostKey = hostPublicKey;
        };
      };
  };

  testScript = ''
    ${(import "${nixpkgs}/nixos/tests/acme/utils.nix").pythonUtils}

    cert = "${domain}"

    dnsserver.start()
    acme.start()

    wait_for_running(dnsserver)
    dnsserver.wait_for_open_port(22)
    dnsserver.wait_for_open_port(53)
    wait_for_running(acme)
    acme.wait_for_open_port(443)

    with subtest("Boot and acquire a new cert"):
        client.start()
        wait_for_running(client)

        check_issuer(client, cert, "pebble")
        check_domain(client, cert, cert)
  '';
}
