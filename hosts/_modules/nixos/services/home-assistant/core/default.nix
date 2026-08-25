{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.services.home-assistant;
in
{
  options.modules.services.home-assistant = {
    enable = lib.mkEnableOption "home-assistant";
  };

  # not using domain

  config = lib.mkIf cfg.enable {
    # 1900,40000 for upnp
    networking.firewall.allowedTCPPorts = [
      40000
      8123
    ];
    networking.firewall.allowedUDPPorts = [ 1900 ];

    systemd.tmpfiles.rules = [
      "d /var/lib/hass 0755 appuser appuser - -"
      "d /var/lib/hass/core 0755 appuser appuser - -"
    ];

    systemd.services.home-assistant.serviceConfig.User = lib.mkForce "appuser";
    systemd.services.home-assistant.serviceConfig.Group = lib.mkForce "appuser";
    users.users.hass.createHome = lib.mkForce false;

    services.home-assistant = {
      enable = true;
      configDir = "/var/lib/hass/core";
      package =
        (pkgs.unstable.home-assistant.overrideAttrs (old: {
          doInstallCheck = false;
        })).override
          {
            extraComponents = [
              "default_config"
              "ffmpeg"
              "homekit"
              "homekit_controller"
              "met"
            ];
          };
      extraPackages =
        python3Packages: with python3Packages; [
          aiohomekit
          gtts
          isal
          pyatv
          python-otbr-api
          radios
          zlib-ng
        ];
      customComponents = with pkgs.unstable.home-assistant-custom-components; [
        midea_ac_lan
        ntfy
        prometheus_sensor
        xiaomi_miot
      ];
      customLovelaceModules = with pkgs.unstable.home-assistant-custom-lovelace-modules; [
        atomic-calendar-revive
        bubble-card
        button-card
        hourly-weather
        mini-graph-card
        mushroom
        multiple-entity-row
      ];

      configWritable = true;
      config = {
        default_config = { };
        frontend = {
          themes = "!include_dir_merge_named themes";
        };
        http = {
          use_x_forwarded_for = "true";
          trusted_proxies = [
            "127.0.0.1"
            "::1"
          ];
        };
      };
    };
  };
}
