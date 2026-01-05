{
  hostname,
  lib,
  ...
}: {
  config = {
    networking = {
      hostName = hostname;
      nameservers = lib.mkForce ["10.0.0.254"];
    };

    systemd.network.networks."10-lan" = {
      matchConfig.Name = "ens18";
      address = [
        "10.0.0.200/24"
      ];
      routes = [
        {
          Gateway = "10.0.0.1";
          GatewayOnLink = true;
        }
      ];
      linkConfig.RequiredForOnline = "routable";
    };
  };
}
