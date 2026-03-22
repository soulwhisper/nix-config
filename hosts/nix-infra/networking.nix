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

    systemd.network.networks."05-lo-virtual" = {
      matchConfig.Name = "lo";
      address = [
        # Fallback virtual IP bound to loopback for services that must be
        # reachable externally via DNS but must remain unreachable from within
        # containers to prevent reverse-proxy loop-back routing loops.
        #
        # External clients resolve the service domain to this address and reach
        # it via a static host route (169.254.10.10/32 -> 10.0.0.200) injected
        # at the gateway; containers have no route to 169.254.0.0/16, so any
        # intra-container proxy_pass targeting this address fails immediately
        # and the application falls back as intended.
        #
        # Do not assign this address to any physical or macvlan interface.
        #
        # dns: xxx A 169.254.10.10
        # gateway: ip route add 169.254.10.10/32 via 10.0.0.200 dev xxx
        "169.254.10.10/32"
      ];
    };

    systemd.network.networks."10-lan" = {
      matchConfig.Name = "ens34"; # proxmox is ens18
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
      networkConfig = {
        DHCP = false;
        IPv6AcceptRA = false;
        LinkLocalAddressing = "ipv4";
      };
    };
  };
}
