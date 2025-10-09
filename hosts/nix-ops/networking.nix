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
    };
  };
}
