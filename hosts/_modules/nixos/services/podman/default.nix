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
    # : compose support is disabled, not-used
    # environment.systemPackages = with pkgs; [
    #   podman-compose
    #   docker-compose
    # ];

    # use `pull = "newer";` to keep image new;
    # podman new network-stack `aardvark` only use `53/tcp_udp` on `podman*`;
    # dns-resolving ref: https://github.com/NixOS/nixpkgs/issues/226365

    virtualisation = {
      podman = {
        enable = true;
        dockerCompat = true; # Create a `docker` alias for podman
        # dockerSocket.enable = true; # docker compose support, not used
        autoPrune = {
          enable = true; # Periodically prune Podman Images not in use.
          dates = "weekly";
          flags = ["--all"];
        };
        # : Enable DNS resolution in the podman default network, not used
        # defaultNetwork.settings.dns_enabled = true;
      };
      oci-containers.backend = "podman";
    };
  };
}
