{
  config,
  pkgs,
  ...
}:
{
  config = {
    home.packages = [
      pkgs.sops
      pkgs.age
    ];

    sops = {
      # :: age
      age = {
        keyFile = "${config.xdg.configHome}/age/keys.txt";
        generateKey = false;
      };

      # :: secrets
      # services enabled by default
      secrets = {
        "dev/deepseek/key" = {
          sopsFile = ./secrets.sops.yaml;
        };
        "shell/atuin/auth" = {
          sopsFile = ./secrets.sops.yaml;
        };
      };
    };

    home.sessionVariables = {
      SOPS_AGE_KEY_FILE = "${config.xdg.configHome}/age/keys.txt";
    };
  };
}
