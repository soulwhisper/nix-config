{
  hostname,
  lib,
  ...
}: {
  config = {
    networking = {
      hostName = hostname;
      firewall.enable = true;
      nftables.enable = true;

      useNetworkd = false; # experimental
      useDHCP = false; # cause conflict
    };

    systemd.network.enable = true;
  };
}
