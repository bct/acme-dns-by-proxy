{
  lib,
  runCommand,
  nixosOptionsDoc,
}:

let
  makeOptionsDoc =
    module:
    nixosOptionsDoc {
      inherit (lib.evalModules { modules = [ module ]; }) options;
    };
  clientDoc = makeOptionsDoc ../nixos-modules/acme-dns-proxy-client/options.nix;
  hostDoc = makeOptionsDoc ../nixos-modules/acme-dns-proxy-host/options.nix;
in
runCommand "acme-dns-by-proxy.nix-doc" { } ''
  mkdir $out
  cp ${hostDoc.optionsCommonMark} $out/host-options.md
  cp ${clientDoc.optionsCommonMark} $out/client-options.md
''
