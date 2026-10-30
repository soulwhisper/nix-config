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
    environment.systemPackages = with pkgs; [
      docker-compose
    ];

    virtualisation.podman.defaultNetwork.settings = {
      dns_enabled = true;
      subnets = [ { subnet = "192.168.10.0/24"; gateway = "192.168.10.1"; } ];
    };

    # : auto-update containers
    # requires: labels = { "io.containers.autoupdate" = "registry"; };
    systemd.timers.podman-auto-update = {
      wantedBy = ["timers.target"];
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
