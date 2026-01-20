# copied from https://github.com/NixOS/nixpkgs/blob/master/nixos/tests/ssh-keys.nix
pkgs: {
  # This key is used in integration tests
  # This is NOT a security issue
  # It uses the same key used in OpenSSH fuzz tests
  # https://github.com/openssh/openssh-portable/blob/V_9_9_P2/regress/misc/fuzz-harness/fixed-keys.h#L76-L85
  snakeOilPrivateKey = pkgs.writeText "privkey.snakeoil" ''
    -----BEGIN OPENSSH PRIVATE KEY-----
    b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAAAMwAAAAtzc2gtZW
    QyNTUxOQAAACAz0F5hFTFS5nhUcmnyjFVoDw5L/P7kQU8JnBA2rWczAwAAAIhWlP99VpT/
    fQAAAAtzc2gtZWQyNTUxOQAAACAz0F5hFTFS5nhUcmnyjFVoDw5L/P7kQU8JnBA2rWczAw
    AAAEDE1rlcMC0s0X3TKVZAOVavZOywwkXw8tO5dLObxaCMEDPQXmEVMVLmeFRyafKMVWgP
    Dkv8/uRBTwmcEDatZzMDAAAAAAECAwQF
    -----END OPENSSH PRIVATE KEY-----
  '';

  snakeOilPublicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDPQXmEVMVLmeFRyafKMVWgPDkv8/uRBTwmcEDatZzMD snakeoil";

  # This key was generated specifically for this purpose using:
  #   cd $(mktemp -d) && ssh-keygen -q -t ed25519 -N "" -f ssh_host
  hostPrivateKey = pkgs.writeText "hostkey.snakeoil" ''
    -----BEGIN OPENSSH PRIVATE KEY-----
    b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAAAMwAAAAtzc2gtZW
    QyNTUxOQAAACDzPXHADXsSbKkVPTPA2xaJjPAwU8GirujXbWsiUzec0gAAAJBib/s4Ym/7
    OAAAAAtzc2gtZWQyNTUxOQAAACDzPXHADXsSbKkVPTPA2xaJjPAwU8GirujXbWsiUzec0g
    AAAEDcQs6LR8V5Fp+09jOW2Cnbe0F0oRaZL7gYZ67nqR2HFvM9ccANexJsqRU9M8DbFomM
    8DBTwaKu6NdtayJTN5zSAAAADWJjdEBhcXVpbG9uaWE=
    -----END OPENSSH PRIVATE KEY-----
  '';

  hostPublicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPM9ccANexJsqRU9M8DbFomM8DBTwaKu6NdtayJTN5zS host";
}
