{ lib, config, ... }:
let
  cfg = config.services.acme-dns-proxy-host;
  authorizedKeys = map (domain: domain.pubKey) cfg.domains;

  mkProviderAssertions = domainCfg: {
    assertion =
      lib.count isNull [
        domainCfg.dnsProvider
        domainCfg.execCommand
      ] == 1;
    message = "${domainCfg.domain}: exactly one of dnsProvider or execCommand must be set.";
  };
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
  ]
  ++ lib.map mkProviderAssertions cfg.domains;
}
