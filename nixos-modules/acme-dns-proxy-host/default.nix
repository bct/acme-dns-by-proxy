{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.services.acme-dns-proxy-host;

  mkCommand =
    {
      domain,
      environmentFile,
      execCommand,
      ...
    }:
    pkgs.writeShellScript "acme-dns-proxy-${domain}" ''
      # parse the command passed by the client.
      #
      # SSH_ORIGINAL_COMMAND is the arguments passed to a lego "External Command"
      # https://go-acme.github.io/lego/dns/exec/index.html#commands
      IFS=" "
      read action fqdn record <<<$SSH_ORIGINAL_COMMAND

      # validate that this client is allowed to access this domain.
      authorized_fqdn="_acme-challenge.${domain}."
      if [ "$fqdn" != "$authorized_fqdn" ]; then
        echo "this key is authorized to modify the domain \"$authorized_fqdn\""
        echo "refusing to proxy request for \"$fqdn\""
        exit 1
      fi

      # log what we're doing.
      echo "acme-dns-proxy: $action $fqdn"

      ${lib.optionalString (environmentFile != null) ''
        # source credentials to pass through to the script
        set -a
        source ${toString environmentFile}
      ''}

      # run the script to modify the DNS
      ${execCommand} "$action" "$fqdn" "$record"
    '';
in
{
  imports = [
    ./asserts.nix
    ./options.nix
  ];

  config = lib.mkIf cfg.enable {
    services.openssh = {
      enable = true;
      # Match blocks need to go at the end of the file.
      extraConfig = lib.mkAfter ''
        Match user ${cfg.user}
          PasswordAuthentication no
          KbdInteractiveAuthentication no
          ChallengeResponseAuthentication no
          PubkeyAuthentication yes
      '';
    };

    users.users.${cfg.user} = {
      isSystemUser = true;
      group = "acme-dns-proxy";

      # system users default to nologin.
      # sshd won't let us execute commands without a shell.
      useDefaultShell = true;

      openssh.authorizedKeys.keys = builtins.map (
        domain: "restrict,command=\"${mkCommand domain}\" ${domain.pubKey}"
      ) cfg.domains;
    };
    users.groups.acme-dns-proxy = { };
  };
}
