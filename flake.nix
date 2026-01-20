{
  description = "NixOS modules for securely responding to ACME DNS challenges";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs =
    { self, nixpkgs }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      forAllSystems = function: nixpkgs.lib.genAttrs systems (system: function system);
    in
    {
      nixosModules = {
        host = ./nixos-modules/acme-dns-proxy-host;
        client = ./nixos-modules/acme-dns-proxy-client;
      };

      packages = forAllSystems (
        system:
        let
          pkgs = import nixpkgs { inherit system; };
        in
        {
          doc = pkgs.callPackage ./pkgs/doc.nix { };
        }
      );

      checks = forAllSystems (
        system:
        let
          pkgs = import nixpkgs { inherit system; };
          checkArgs = { inherit self pkgs nixpkgs; };
        in
        {
          acme-dns-proxy-host = pkgs.testers.runNixOSTest (import ./checks/acme-dns-proxy-host.nix checkArgs);

          acme-dns-proxy-e2e = pkgs.testers.runNixOSTest (import ./checks/acme-dns-proxy-e2e.nix checkArgs);
        }
      );
    };
}
