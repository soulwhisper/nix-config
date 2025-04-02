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
      podman-compose
      docker-compose
    ];

    # with "adguardhome" port remap to 5300, containerName could be resolved;
    # no longer needs "host.containers.internal:${port}", reduce complexity;
    # also, use `extraOptions = ["--pull=newer"];` to keep image new;

    # podman now use `netavark` network stack
    # `podman info --format {{.Host.NetworkBackend}}`
    # dns-resolving ref: https://github.com/NixOS/nixpkgs/issues/226365

    # Required by podman for rootless mode.
    security.unprivilegedUsernsClone = true;

    virtualisation = {
      podman = {
        enable = true;
        dockerCompat = true; # Create a `docker` alias for podman
        dockerSocket.enable = true; # docker compose support
        autoPrune = {
          enable = true; # Periodically prune Podman Images not in use.
          dates = "weekly";
          flags = ["--all"];
        };
        defaultNetwork.settings = {
          dns_enabled = true; # Enable DNS resolution in the podman network.
        };
      };
      oci-containers.backend = "podman";
    };
  };
}
