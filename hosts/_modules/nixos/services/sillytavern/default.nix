{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.services.sillytavern;
  reverseProxyCaddy = config.modules.services.caddy;
in {
  options.modules.services.sillytavern = {
    enable = lib.mkEnableOption "sillytavern";
    domain = lib.mkOption {
      type = lib.types.str;
      default = "tavern.noirprime.com";
    };
  };

  config = lib.mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = lib.mkIf (!reverseProxyCaddy.enable) [8000];

    services.caddy.virtualHosts."${cfg.domain}".extraConfig = lib.mkIf reverseProxyCaddy.enable ''
      handle {
        reverse_proxy localhost:8000
      }
    '';
    environment.systemPackages = [ pkgs.unstable.koboldcpp ];

    # model:"https://huggingface.co/unsloth/DeepSeek-R1-0528-Qwen3-8B-GGUF/blob/main/DeepSeek-R1-0528-Qwen3-8B-Q4_K_M.gguf"
    # add characters via:https://github.com/HiUnikitty/Nika-Character-Studio
    # test models via:https://github.com/lmg-anon/mikupad/releases/download/release513/mikupad_compiled.html

    systemd.tmpfiles.rules = [
      "d /var/lib/sillytavern 0755 appuser appuser - -"
      "d /var/lib/sillytavern/config 0755 appuser appuser - -"
      "d /var/lib/sillytavern/data 0755 appuser appuser - -"
      "d /var/lib/sillytavern/plugins 0755 appuser appuser - -"
    ];

    systemd.services.sillytavern = {
      description = "LLM Frontend for Power Users";
      wants = ["network-online.target"];
      after = ["network-online.target"];
      wantedBy = ["multi-user.target"];
      unitConfig = {
        StartLimitIntervalSec = 0;
      };
      serviceConfig = {
        User = "appuser";
        Group = "appuser";
        ExecStart = "${pkgs.sillytavern}/bin/sillytavern";
        RuntimeDirectory = "sillytavern";
        StateDirectory = "sillytavern";
        Restart = "always";
        RestartSec = 5;
      };
    };
  };
}
