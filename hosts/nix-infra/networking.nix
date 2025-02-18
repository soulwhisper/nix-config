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
      nameservers = lib.mkForce ["127.0.0.1"]; # adguard
      useNetworkd = false; # experimental
      useDHCP = false; # cause conflict
    };

    systemd.network.enable = true;
  };
}
