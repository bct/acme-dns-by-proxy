{ lib, config, ... }:
let
  authorizedKeys = map (domain: domain.pubKey) config.services.acme-dns-proxy-host.domains;
in
{
  # this restriction is a little silly, but it simplifies the implementation:
  # if each key maps to exactly one domain, then we only need to check that single
  # domain when the client makes a request.
  assertions = [
    {
      assertion = lib.allUnique authorizedKeys;
      message = "services.acme-dns-proxy-host.domains.*.pubKey must be unique";
    }
  ];
}
