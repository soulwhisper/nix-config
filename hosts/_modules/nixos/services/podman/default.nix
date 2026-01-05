{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.services.podman;
in {
  options.modules.services.podman = {
    enable = lib.mkEnableOption "podman";
  };

  config = lib.mkIf cfg.enable {
    # : compose support
    environment.systemPackages = with pkgs; [
      docker-compose
    ];

    # : dns-resolving, needs 53/udp on 'podman*'(nftables)
    # https://github.com/NixOS/nixpkgs/issues/226365
    # networking.firewall.interfaces."podman*".allowedUDPPorts = [53 5353];
    # networking.dhcpcd.IPv6rs = false;
    # virtualisation.podman.defaultNetwork.settings.dns_enabled = true;

    # : auto-update containers
    # requires: labels = { "io.containers.autoupdate" = "registry"; };
    systemd.timers.podman-auto-update = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "daily";
        Persistent = true;
        RandomizedDelaySec = 3600;
      };
    };

    virtualisation = {
      oci-containers.backend = "podman";
      podman = {
        enable = true;
        dockerCompat = true;
        dockerSocket.enable = true;
        autoPrune = {
          enable = true;
          dates = "weekly";
          flags = ["--all"];
        };
      };
    };
  };
}
