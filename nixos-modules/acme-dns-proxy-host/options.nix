{ lib, ... }:
{
  options.services.acme-dns-proxy-host = with lib; {
    enable = mkEnableOption "acme-dns-proxy-host";

    user = mkOption {
      type = lib.types.str;
      default = "acme-dns-proxy";
      description = ''
        The user that will execute the proxied commands.

        This module creates and configures this user. The user should not be used for anything else.
      '';
    };

    domains = mkOption {
      type = types.listOf (
        types.submodule (
          { config, ... }:
          {
            options = {
              domain = mkOption {
                type = types.str;
                description = ''
                  An FQDN that we are allowed to act as a proxy for.
                '';
                example = "subdomain.example.org";
              };

              pubKey = mkOption {
                type = types.singleLineStr;
                description = ''
                  An SSH client public key that is authorized to use this DNS challenge proxy.
                '';
                example = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMi/bg+PkUxp5XmisRyxcmeI5cUjST0AJ0+xleFFAIZg user@client";
              };

              dnsProvider = mkOption {
                type = types.nullOr types.str;
                default = null;
                description = ''
                  DNS Challenge provider. For a list of supported providers, see the "code" field of the DNS providers listed at https://go-acme.github.io/lego/dns/.

                  Mutually exclusive with `execCommand`.
                '';
              };

              execCommand = mkOption {
                type = types.nullOr (
                  types.oneOf [
                    types.str
                    types.path
                  ]
                );
                default = null;
                description = ''
                  A command that will be executed when the authorized client uses this proxy.

                  This command should expect the arguments of a lego "External Command" DNS provider:
                  https://go-acme.github.io/lego/dns/exec/index.html#commands

                  Mutually exclusive with `dnsProvider`.
                '';
              };

              environmentFile = mkOption {
                type = types.nullOr types.path;
                default = null;
                description = ''
                  A Bash file that will be `source`d to provide additional environment variables (e.g. secrets).
                '';
              };

              rawMode = mkOption {
                type = types.bool;
                default = config.dnsProvider != null;
                description = ''
                  Pass the raw domain and key authorization string to the `execCommand`?

                  If false, the domain will look like _acme-challenge.your-domain.example, and the authorization string will be the exact string that should be set on the TXT record.
                  If true, the domain will look like your-domain.example, and the authorization string will need to be SHA256ed before setting the TXT record.

                  Must be `true` to use `dnsProvider`.
                '';
              };
            };
          }
        )
      );

      default = [ ];
      description = ''
        A list of domains that we are allowed to act as a proxy for.
      '';

      example = lib.literalExpression ''
        [
          {
            domain = "subdomain.example.org";
            pubKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMi/bg+PkUxp5XmisRyxcmeI5cUjST0AJ0+xleFFAIZg user@client";
            execCommand = "/path/to/script";
          }
        ]
      '';
    };
  };
}
