{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.services.karakeep;
  reverseProxyCaddy = config.modules.services.caddy;
in {
  options.modules.services.karakeep = {
    enable = lib.mkEnableOption "karakeep";
    domain = lib.mkOption {
      type = lib.types.str;
      default = "bookmarks.noirprime.com";
    };
  };

  config = lib.mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = lib.mkIf (!reverseProxyCaddy.enable) [9802];

    services.caddy.virtualHosts."${cfg.domain}".extraConfig = lib.mkIf reverseProxyCaddy.enable ''
      handle {
        reverse_proxy localhost:9802
      }
    '';

    # nix package is outdated

    services.karakeep = {
      enable = true;
      package = pkgs.unstable.karakeep;
      extraEnvironment = {
        PORT = "9802";
        DISABLE_SIGNUPS = "false";
        DISABLE_NEW_RELEASE_CHECK = "true";
        NEXTAUTH_URL = "https://${cfg.domain}";
      };
    };
  };
}
