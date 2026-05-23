self:

{
  lib,
  pkgs,
  config,
  ...
}:
let
  proxyClient = pkgs.writeShellScript "acme-dns-proxy-client" ''
    ${pkgs.openssh}/bin/ssh -i "$ACME_DNS_PROXY_IDENTITY" "$ACME_DNS_PROXY_REMOTE_USER"@"$ACME_DNS_PROXY_HOST" "$@"
  '';

  hostKeys = lib.mapAttrs' (
    _: proxy: lib.nameValuePair proxy.host { publicKey = proxy.hostKey; }
  ) config.security.acme.dnsChallengeProxies;
in
{
  imports = [
    ./options.nix
  ];

  config = {
    security.acme.certs = lib.mapAttrs (domain: proxy: {
      dnsProvider = "exec";
    }) config.security.acme.dnsChallengeProxies;

    systemd.services = lib.mapAttrs' (
      cert: proxy:
      lib.nameValuePair "acme-order-renew-${cert}" {
        environment = {
          EXEC_PATH = toString proxyClient;
          EXEC_PROPAGATION_TIMEOUT = "180";
          ACME_DNS_PROXY_REMOTE_USER = proxy.remoteUser;
          ACME_DNS_PROXY_HOST = proxy.host;
          ACME_DNS_PROXY_IDENTITY = proxy.sshIdentity;
        }
        // lib.optionalAttrs proxy.rawMode { EXEC_MODE = "RAW"; };
      }
    ) config.security.acme.dnsChallengeProxies;

    programs.ssh.knownHosts = hostKeys;
  };
}
