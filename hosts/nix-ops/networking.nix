{
  hostname,
  lib,
  ...
}: {
  config = {
    networking = {
      hostName = hostname;
    };

    systemd.network.networks."10-lan" = {
      matchConfig.Name = "ens192";
      address = [
        "172.19.82.10/24"
      ];
      routes = [
        {
          Gateway = "172.19.82.1";
          GatewayOnLink = true;
        }
      ];
      linkConfig.RequiredForOnline = "routable";
      networkConfig = {
        DHCP = "no";
        DNS = "127.0.0.1"; # adguardhome
        IPv6AcceptRA = false;
        LinkLocalAddressing = "ipv4";
      };
    };
  };
}
