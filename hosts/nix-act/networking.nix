{
  hostname,
  lib,
  ...
}:
{
  config = {
    networking = {
      hostName = hostname;
      nameservers = [ "10.10.0.254" ];
    };

    systemd.network.networks."10-lan" = {
      # N100 mini-PCs expose enp*/eno* or eth0 depending on firmware.
      matchConfig.Name = "en* eth*";
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
