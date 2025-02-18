{
  pkgs,
  lib,
  config,
  hostname,
  ...
}: {
  config = {
    systemd.network.enable = true;
    networking = {
      hostName = hostname;

      # use networkd instead of scripts, disable dhcpd
      useNetworkd = true;
      useDHCP = false;

      # enable nftables for firewall
      firewall.enable = true;
      nftables.enable = true;
    };
  };
}
