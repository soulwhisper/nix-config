{
  config,
  pkgs,
  ...
}:
{
  config = {
    sops = {
      defaultSopsFile = ./secrets.sops.yaml;
      secrets = {
        "pki/root-ca-crt" = {
          mode = "0444";
          restartUnits = [
            "pki-publish.service"
            "step-ca.service"
            "caddy.service"
          ];
        };
        "pki/intermediate-crt" = {
          mode = "0444";
          restartUnits = [ "step-ca.service" ];
        };
        "pki/intermediate-key" = {
          owner = config.users.users.appuser.name;
          mode = "0400";
          restartUnits = [ "step-ca.service" ];
        };
        "pki/intermediate-password" = {
          mode = "0400";
          restartUnits = [ "step-ca.service" ];
        };
        "storage/versitygw/auth" = {
          owner = config.users.users.appuser.name;
          restartUnits = [ "versitygw.service" ];
        };
      };
    };
  };
}
