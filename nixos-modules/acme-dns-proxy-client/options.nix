{ lib, ... }:
{
  options.security.acme.dnsChallengeProxies =
    with lib;
    lib.mkOption {
      default = { };
      description = ''
        The set of ACME domains that should use the proxy.
      '';
      example = lib.literalExpression ''
        {
          "subdomain.example.org" = {
            host = "acme-dns-proxy.example.org";
            sshIdentity = "/path/to/id_ed25519";
            hostKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMi/bg+PkUxp5XmisRyxcmeI5cUjST0AJ0+xleFFAIZg";
          }
        }
      '';
      type = types.attrsOf (
        types.submodule (
          { ... }:
          {
            options = {
              remoteUser = mkOption {
                type = lib.types.str;
                default = "acme-dns-proxy";
                example = "acme-dns-proxy";
                description = ''
                  The name of the remote user provided by the proxy.
                '';
              };

              host = mkOption {
                type = lib.types.str;
                example = "acme-dns-proxy.example.org";
                description = ''
                  The host that provides the proxy.
                '';
              };

              hostKey = mkOption {
                type = lib.types.str;
                example = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMi/bg+PkUxp5XmisRyxcmeI5cUjST0AJ0+xleFFAIZg";
                description = ''
                  The proxy's SSH host key.
                '';
              };

              sshIdentity = mkOption {
                type = lib.types.str;
                example = "/path/to/id_ed25519";
                description = ''
                  The path to the SSH client private key that the proxy has authorized to modify this domain.
                '';
              };
            };
          }
        )
      );
    };
}
