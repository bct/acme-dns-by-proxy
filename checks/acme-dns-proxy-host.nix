# This test validates the acme-dns-proxy host module access controls.
#
# There are 2 hosts here:
#
# - "host" hosts an acme-dns-proxy
# - "client" attempts to execute commands on the acme-dns-proxy account.
#
# The test passes iff authorized clients can execute authorized commands.
{
  self,
  pkgs,
  nixpkgs,
}:
let
  inherit (import ./ssh-keys.nix pkgs) snakeOilPrivateKey snakeOilPublicKey;
in
{
  name = "acme-dns-proxy-host";

  nodes.host =
    { config, pkgs, ... }:
    {
      imports = [ self.nixosModules.host ];

      services.acme-dns-proxy-host = {
        enable = true;

        domains = [
          {
            domain = "authorized-subdomain.example.org";
            execCommand = pkgs.writeShellScript "host-exec" ''
              echo $@ >>/tmp/proxy-requests
            '';
            pubKey = snakeOilPublicKey;
          }
        ];
      };

      system.stateVersion = "25.11";
    };

  nodes.client =
    { config, pkgs, ... }:
    {
      system.stateVersion = "25.11";
    };

  testScript = ''
    def ssh_command(domain, keyfile="/root/.ssh/id_ed25519"):
      fqdn = f"_acme-challenge.{domain}."
      return f"ssh acme-dns-proxy@host -i {keyfile} -- present {fqdn} some-token"

    start_all()

    client.succeed("mkdir -m 700 /root/.ssh")
    client.succeed("cat '${snakeOilPrivateKey}' | tee /root/.ssh/id_ed25519")
    client.succeed("chmod 600 /root/.ssh/id_ed25519")

    host.wait_for_unit("sshd")
    client.succeed("ssh-keyscan -H host | tee -a /root/.ssh/known_hosts")

    # the proxy executes the script for an authorized subdomain
    client.succeed(ssh_command("authorized-subdomain.example.org"))

    # the proxy does not execute the script for an unauthorized subdomain
    client.fail(ssh_command("other-subdomain.example.org"))

    # the proxy does not execute the script given an unauthorized client key
    client.succeed('ssh-keygen -N "" -t ed25519 -f /tmp/new-key')
    client.fail(ssh_command("authorized-subdomain.example.org", keyfile="/tmp/new-key"))

    # the proxy does not execute arbitrary commands
    client.fail("ssh acme-dns-proxy@host -- whoami")

    # check what was successfully executed
    t.assertEqual(
      "present _acme-challenge.authorized-subdomain.example.org. some-token\n",
      host.succeed("cat /tmp/proxy-requests")
    )
  '';
}
