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
    systemd.network.networks."10-lan" = {
      matchConfig.Name = "enp6s18";
      address = [
        "10.0.0.10/24"
      ];
      routes = [
        {
          Gateway = "10.0.0.1";
          GatewayOnLink = true;
        }
      ];
      linkConfig.RequiredForOnline = "routable";
    };
    systemd.network.networks."20-wifi" = {
      matchConfig.Name = "enp6s19";
      address = [
        "10.20.0.10/24"
      ];
      linkConfig.RequiredForOnline = "no";
    };
  };
}
