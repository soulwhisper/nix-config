{
  hostname,
  lib,
  ...
}:
{
  config = {
    networking = {
      hostName = hostname;
      nameservers = [ "127.0.0.1" ];
    };

    systemd.network.networks."10-lan" = {
      # SmartX virtio NICs enumerate as enp*/ens*; ens192 was the ESXi vmxnet3.
      matchConfig.Name = "en*";
      address = [
        "172.19.162.10/24"
      ];
      routes = [
        {
          Gateway = "172.19.162.1";
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
