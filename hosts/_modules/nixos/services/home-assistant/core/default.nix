{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.services.home-assistant;
  reverseProxyCaddy = config.modules.services.caddy;
in {
  options.modules.services.home-assistant = {
    enable = lib.mkEnableOption "home-assistant";
    domain = lib.mkOption {
      type = lib.types.str;
      default = "hass.noirprime.com";
    };
  };

  config = lib.mkIf cfg.enable {
    # 1900,40000 for upnp
    networking.firewall.allowedTCPPorts = [
      40000
      (lib.mkIf (!reverseProxyCaddy.enable) 8123)
    ];
    networking.firewall.allowedUDPPorts = [1900];

    services.caddy.virtualHosts."${cfg.domain}".extraConfig = lib.mkIf reverseProxyCaddy.enable ''
      handle {
        reverse_proxy localhost:8123
      }
    '';

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
        }))
        .override {
          extraComponents = [
            "default_config"
            "ffmpeg"
            "homekit"
            "homekit_controller"
            "met"
          ];
        };
      extraPackages = python3Packages:
        with python3Packages; [
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
        default_config = {};
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
        template = [
          {
            trigger = [
              {
                platform = "event";
                event_type = "state_changed";
                event_data = {
                  entity_id = "sensor.electricity_charge_balance_xxxx"; # todo, correct xxx after hass-sgcc deployment
                };
              }
            ];
            sensor = [
              {
                name = "electricity_charge_balance_xxxx";
                unique_id = "electricity_charge_balance_xxxx";
                state = "{{ states('sensor.electricity_charge_balance_xxxx') }}";
                state_class = "total";
                unit_of_measurement = "CNY";
                device_class = "monetary";
              }
            ];
          }
          {
            trigger = [
              {
                platform = "event";
                event_type = "state_changed";
                event_data = {
                  entity_id = "sensor.last_electricity_usage_xxxx";
                };
              }
            ];
            sensor = [
              {
                name = "last_electricity_usage_xxxx";
                unique_id = "last_electricity_usage_xxxx";
                state = "{{ states('sensor.last_electricity_usage_xxxx') }}";
                state_class = "measurement";
                unit_of_measurement = "kWh";
                device_class = "energy";
              }
            ];
          }
          {
            trigger = [
              {
                platform = "event";
                event_type = "state_changed";
                event_data = {
                  entity_id = "sensor.month_electricity_usage_xxxx";
                };
              }
            ];
            sensor = [
              {
                name = "month_electricity_usage_xxxx";
                unique_id = "month_electricity_usage_xxxx";
                state = "{{ states('sensor.month_electricity_usage_xxxx') }}";
                state_class = "measurement";
                unit_of_measurement = "kWh";
                device_class = "energy";
              }
            ];
          }
          {
            trigger = [
              {
                platform = "event";
                event_type = "state_changed";
                event_data = {
                  entity_id = "sensor.month_electricity_charge_xxxx";
                };
              }
            ];
            sensor = [
              {
                name = "month_electricity_charge_xxxx";
                unique_id = "month_electricity_charge_xxxx";
                state = "{{ states('sensor.month_electricity_charge_xxxx') }}";
                state_class = "measurement";
                unit_of_measurement = "CNY";
                device_class = "monetary";
              }
            ];
          }
          {
            trigger = [
              {
                platform = "event";
                event_type = "state_changed";
                event_data = {
                  entity_id = "sensor.yearly_electricity_usage_xxxx";
                };
              }
            ];
            sensor = [
              {
                name = "yearly_electricity_usage_xxxx";
                unique_id = "yearly_electricity_usage_xxxx";
                state = "{{ states('sensor.yearly_electricity_usage_xxxx') }}";
                state_class = "total_increasing";
                unit_of_measurement = "kWh";
                device_class = "energy";
              }
            ];
          }
          {
            trigger = [
              {
                platform = "event";
                event_type = "state_changed";
                event_data = {
                  entity_id = "sensor.yearly_electricity_charge_xxxx";
                };
              }
            ];
            sensor = [
              {
                name = "yearly_electricity_charge_xxxx";
                unique_id = "yearly_electricity_charge_xxxx";
                state = "{{ states('sensor.yearly_electricity_charge_xxxx') }}";
                state_class = "total_increasing";
                unit_of_measurement = "CNY";
                device_class = "monetary";
              }
            ];
          }
        ];
      };
    };
  };
}
