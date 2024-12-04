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

    environment.etc = {
        "gatus/config.yaml".source = pkgs.writeTextFile {
        name = "config.yaml";
        text = builtins.readFile ./config.yaml;
        };
        "gatus/config.yaml".mode = "0600";
        "gatus/.env".source = pkgs.writeTextFile {
        name = "env";
        text = builtins.readFile ./.env;
        };
        "gatus/.env".mode = "0600";
    };

    services.gatus = {
      enable = true;
      package = pkgs.unstable.gatus;
      configFile = "/etc/gatus/config.yaml";
      environmentFile = "/etc/gatus/.env";
    };
  };
}
