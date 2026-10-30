{
  hostname,
  lib,
  ...
}: {
  config = {
    networking = {
      hostName = hostname;
      nameservers = [ "10.10.0.254" ];
    };

    systemd.network.networks."10-lan" = {
      matchConfig.Name = "eth0";
      address = [
        "10.10.0.220/24"
      ];
      routes = [
        {
          Gateway = "10.10.0.1";
          GatewayOnLink = true;
        }
      ];
      linkConfig.RequiredForOnline = "routable";
      networkConfig = {
        DHCP = false;
        IPv6AcceptRA = false;
        LinkLocalAddressing = "ipv4";
      };
    };
  };
}
