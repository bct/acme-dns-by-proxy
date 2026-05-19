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
          inherit (nixpkgs) lib;
        in
        {
          doc = pkgs.callPackage ./pkgs/doc.nix { };

          lego-dns-provider = pkgs.buildGoModule {
            name = "lego-dns-provider";
            src = lib.cleanSource ./lego-dns-provider;
            vendorHash = "sha256-iPGsfdf6po2eSVWCXv6Xd2ZVe1Vpvf+xUgfWE1V5+v8=";
          };
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

      devShells = forAllSystems (
        system:
        let
          pkgs = import nixpkgs { inherit system; };
        in

        {
          default = pkgs.mkShell {
            buildInputs = [
              pkgs.go
            ];
          };
        }
      );
    };
}
