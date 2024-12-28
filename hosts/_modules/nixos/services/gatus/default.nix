{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.modules.services.gatus;
in
{
  options.modules.services.gatus = {
    enable = lib.mkEnableOption "gatus";
  };

  config = lib.mkIf cfg.enable {
    services.caddy.virtualHosts."mon.noirprime.com".extraConfig = ''
      handle {
	      reverse_proxy localhost:9801
      }
    '';

    # networking.firewall.allowedTCPPorts = [ 9801 ];

    environment.etc = {
        "gatus/config.yaml".source = pkgs.writeTextFile {
        name = "config.yaml";
        text = builtins.readFile ./config.yaml;
        };
        "gatus/config.yaml".mode = "0644";
        "gatus/.env".source = pkgs.writeTextFile {
        name = "env";
        text = builtins.readFile ./.env;
        };
        "gatus/.env".mode = "0644";
    };

    systemd.services.gatus = {
      description = "Automated developer-oriented status page";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "simple";
        Restart = "on-failure";
        ExecStartPre =
        [
          "/bin/sh -c '[[ -f state.binpb ]] || touch state.binpb'"
        ];
        ExecStart = lib.getExe pkgs.unstable.gatus;
        StateDirectory = "gatus";
        SyslogIdentifier = "gatus";
        EnvironmentFile = "/etc/gatus/.env";
      };
      environment = {
        GATUS_CONFIG_PATH = "/etc/gatus/config.yaml";
      };
    };
  };
}
