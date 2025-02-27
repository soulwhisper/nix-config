{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.modules.services.home-assistant;
in {
  config = lib.mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = [8123 40000]; # 40000-40100 for upnp
    networking.firewall.allowedUDPPorts = [1900 5353];
    networking.firewall.allowedUDPPortRanges = [{ from = 32768; to = 65535; }];

    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir}/core 0755 appuser appuser - -"
    ];
    systemd.services.home-assistant.serviceConfig.User = lib.mkForce "appuser";
    systemd.services.home-assistant.serviceConfig.Group = lib.mkForce "appuser";
    users.users.hass.createHome = lib.mkForce false;

    services.home-assistant = {
      enable = true;
      configDir = "${cfg.dataDir}/core";
      package = pkgs.unstable.home-assistant.override {
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
