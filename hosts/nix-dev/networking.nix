{
  pkgs,
  lib,
  config,
  hostname,
  ...
}: {
  config = {
    networking = {
      hostName = hostname;
      firewall.enable = true;
      nftables.enable = true;
      useDHCP = true;
    };
  };
}