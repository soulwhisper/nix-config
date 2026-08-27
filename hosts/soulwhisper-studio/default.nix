{
  hostname,
  pkgs,
  ...
}: {
  # Mac Studio · M5 Max · 64GB unified memory · local AI inference appliance.
  # Model stack, memory budget and rationale: ./README.md
  config = {
    networking = {
      computerName = "soulwhisper-studio";
      hostName = hostname;
      localHostName = hostname;
    };

    # Raise the GPU wired memory ceiling to 56GB (leaves ~8GB for macOS).
    # sysctl does not persist across reboots; this launchd daemon re-applies it
    # at every boot. See README.md §memory-budget.
    launchd.daemons.iogpu-wired-limit = {
      script = ''
        /usr/sbin/sysctl iogpu.wired_limit_mb=57344
      '';
      serviceConfig = {
        RunAtLoad = true;
        KeepAlive = false;
      };
    };

    # Always-on inference server: never sleep, restart after power failure.
    system.activationScripts.postActivation.text = ''
      /usr/bin/pmset -a sleep 0 displaysleep 15 powernap 0 tcpkeepalive 1 autorestart 1
    '';

    environment.systemPackages = with pkgs; [
      uv # python envs for the JoyAI MLX rewrite (vllm-omni adapter, streaming pipeline)
    ];

    homebrew = {
      taps = [
        {
          name = "jundot/omlx";
          clone_target = "https://github.com/jundot/omlx";
          trusted = true;
        }
      ];
      brews = [
        # oMLX inference server (CLI only; menu-bar app is a one-time DMG install).
        # Lifecycle: `omlx start|stop|restart` (delegates to brew services).
        "jundot/omlx/omlx"
      ];
      casks = [
      ];
    };
  };
}
