{
  hostname,
  lib,
  ...
}: {
  config = {
    networking = {
      hostName = hostname;
      nameservers = lib.mkForce ["127.0.0.1"]; # local-dns
    };

    systemd.network.networks."10-lab" = {
      matchConfig.Name = "enp6s18";
      address = [
        "10.10.0.200/24"
      ];
      routes = [
        {
          Gateway = "10.10.0.1";
          GatewayOnLink = true;
        }
      ];
      linkConfig.RequiredForOnline = "routable";
    };
    systemd.network.networks."20-mgmt" = {
      matchConfig.Name = "enp6s19";
      address = [
        "10.0.0.200/24"
      ];
      linkConfig.RequiredForOnline = "no";
    };
  };
}
