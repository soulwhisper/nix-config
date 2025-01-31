{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.modules.services.home-assistant;
in {
  config = lib.mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = [8123]; # use ip:port in case network fails

    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir}/core 0755 appuser appuser - -"
    ];
    systemd.services.home-assistant.serviceConfig.User = lib.mkForce "appuser";
    systemd.services.home-assistant.serviceConfig.Group = lib.mkForce "appuser";

    services.home-assistant = {
      enable = true;
      configDir = "${cfg.dataDir}/core";

      extraComponents = [
        "default_config"
        "homekit_controller"
        "matter"
        "met"
        "openweathermap"
      ];
      extraPackages = python3Packages: with python3Packages; [
        isal
        pyatv
        zlib-ng
      ];
      customComponents = with pkgs.home-assistant-custom-components; [
        midea_ac_lan
        ntfy
        prometheus_sensor
        xiaomi_miot
      ];
      customLovelaceModules = with pkgs.home-assistant-custom-lovelace-modules; [
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
        homeassistant = {
          name = "Home";
          latitude = "45.8";
          longitude = "126.4";
          unit_system = "metric";
          time_zone = "Asia/Shanghai";
          temperature_unit = "C";
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

      lovelaceConfigWritable = true;
      lovelaceConfig = {
        views = [
          {
            title = "Home";
            path = "home";
            type = "sections";
            sections = [
              {
                type = "grid";
                cards = [
                  {
                    show_current = true;
                    show_forecast = true;
                    type = "weather-forecast";
                    entity = "weather.forecast_wo_de_jia";
                    forecast_type = "daily";
                  }
                  {
                    type = "markdown";
                    content = "- 标题开关仅控制开关，不含窗帘";
                  }
                  {
                    type = "grid";
                    square = false;
                    columns = 1;
                    cards = [
                      {
                        type = "entities";
                        entities = [
                          {entity = "cover.curtain";}
                          {entity = "switch.wall_switch_switch1_2";}
                          {entity = "switch.wall_switch_switch2";}
                          {entity = "switch.wall_switch_switch3";}
                          {entity = "switch.wall_switch_switch2_2";}
                          {entity = "switch.wall_switch_2";}
                          {entity = "switch.wall_switch";}
                        ];
                        title = "客厅";
                        show_header_toggle = true;
                      }
                    ];
                  }
                  {
                    type = "entities";
                    entities = [
                      "switch.wall_switch_switch1_3"
                      "switch.wall_switch_switch2_3"
                    ];
                    title = "厨房";
                    show_header_toggle = true;
                  }
                ];
              }
              {
                type = "grid";
                cards = [
                  {
                    type = "custom:mini-graph-card";
                    entities = [
                      {
                        entity = "sensor.last_electricity_usage";
                        name = "国网七天用电曲线";
                        aggregate_func = "first";
                        show_state = true;
                        show_points = true;
                      }
                    ];
                    group_by = "date";
                    hour24 = true;
                    hours_to_show = 240;
                  }
                  {
                    type = "custom:mushroom-entity-card";
                    entity = "sensor.month_electricity_charge";
                    icon = "mdi:home";
                    name = "上月国网电费";
                    tap_action = {action = "none";};
                    hold_action = {action = "none";};
                    double_tap_action = {action = "none";};
                    icon_type = "icon";
                    fill_container = false;
                    layout_options = {
                      grid_columns = 4;
                      grid_rows = 1;
                    };
                  }
                  {
                    type = "custom:mushroom-entity-card";
                    entity = "sensor.yearly_electricity_charge";
                    name = "今年国网总电费";
                    icon = "mdi:currency-cny";
                    layout_options = {
                      grid_columns = 2;
                      grid_rows = 1;
                    };
                    tap_action = {action = "none";};
                    hold_action = {action = "none";};
                    double_tap_action = {action = "none";};
                    fill_container = true;
                  }
                  {
                    type = "custom:mushroom-entity-card";
                    entity = "sensor.yearly_electricity_usage";
                    name = "今年国网总电量";
                    icon = "mdi:lightning-bolt";
                    tap_action = {action = "none";};
                    hold_action = {action = "none";};
                    double_tap_action = {action = "none";};
                  }
                  {
                    type = "tile";
                    entity = "climate.211106241676463_climate";
                    layout_options = {
                      grid_columns = 4;
                      grid_rows = 1;
                    };
                    features = [
                      {type = "climate-hvac-modes";}
                    ];
                  }
                  {
                    type = "entities";
                    entities = [
                      "switch.wall_switch_switch2_4"
                      "switch.wall_switch_switch3_2"
                      "switch.wall_switch_switch1_4"
                    ];
                    title = "书房";
                    show_header_toggle = true;
                  }
                  {
                    type = "entities";
                    entities = [
                      "cover.curtain_2"
                      "switch.wall_switch_switch1_5"
                      "switch.wall_switch_switch2_5"
                    ];
                    title = "卧室";
                    show_header_toggle = true;
                  }
                ];
              }
            ];
            max_columns = 2;
            cards = [];
          }
          {
            path = "default_view";
            title = "Default";
            cards = [
              {
                type = "grid";
                square = false;
                columns = 1;
                cards = [
                  {
                    type = "entities";
                    entities = [
                      {entity = "cover.curtain";}
                      {entity = "switch.wall_switch_switch1_2";}
                      {entity = "switch.wall_switch_switch2";}
                      {entity = "switch.wall_switch_switch3";}
                      {entity = "switch.wall_switch_switch2_2";}
                      {entity = "switch.wall_switch_2";}
                      {entity = "switch.wall_switch";}
                    ];
                    title = "客厅";
                  }
                ];
              }
              {
                type = "entities";
                entities = [
                  "switch.wall_switch_switch1_3"
                  "switch.wall_switch_switch2_3"
                ];
                title = "厨房";
              }
              {
                type = "entities";
                entities = [
                  "cover.curtain_2"
                  "switch.wall_switch_switch1_5"
                  "switch.wall_switch_switch2_5"
                ];
                title = "卧室";
              }
              {
                type = "entities";
                entities = [
                  "switch.wall_switch_switch2_4"
                  "switch.wall_switch_switch3_2"
                  "switch.wall_switch_switch1_4"
                ];
                title = "书房";
              }
              {
                show_current = true;
                show_forecast = true;
                type = "weather-forecast";
                entity = "weather.forecast_wo_de_jia";
                forecast_type = "daily";
              }
            ];
            visible = [];
          }
        ];
      };
    };
  };
}
