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
      matchConfig.Name = "ens34"; # proxmox is ens18
      address = [
        "10.10.0.200/24"
      ];
      routes = [
        {
          Gateway = "10.10.0.1";
          GatewayOnLink = true;
        }
        {
          Destination = "10.0.0.0/24";
          Gateway = "10.10.0.1";
        }
      ];
      linkConfig.RequiredForOnline = "routable";
      networkConfig = {
        DHCP = false;
        DNS = "10.10.0.254";
        IPv6AcceptRA = false;
        LinkLocalAddressing = "ipv4";
      };
    };
  };
}
