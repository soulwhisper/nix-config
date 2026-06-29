{
  hostname,
  lib,
  ...
}: {
  config = {
    networking = {
      hostName = hostname;
    };
    environment.etc."resolvconf/resolv.conf.d/head".text = ''
      # prefer local dns
      nameserver 127.0.0.1
    '';

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
        DHCP = false;
        IPv6AcceptRA = false;
        LinkLocalAddressing = "ipv4";
      };
    };
  };
}
