{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.desktop;
in {
  config = lib.mkIf cfg.enable {
    # ref:https://github.com/ryan4yin/nix-config/blob/main/modules/nixos/desktop/peripherals.nix

    #============================= Audio(PipeWire) =======================

    environment.systemPackages = with pkgs; [
      pulseaudio # provides `pactl`, which is required by some apps(e.g. sonic-pi)
    ];
    # PipeWire is a new low-level multimedia framework.
    # It aims to offer capture and playback for both audio and video with minimal latency.
    # It support for PulseAudio-, JACK-, ALSA- and GStreamer-based applications.
    # PipeWire has a great bluetooth support, it can be a good alternative to PulseAudio.
    #     https://nixos.wiki/wiki/PipeWire
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;
      wireplumber.enable = true;
    };
    # rtkit is optional but recommended
    security.rtkit.enable = true;
    # Disable pulseaudio, it conflicts with pipewire too.
    services.pulseaudio.enable = false;

    #============================= Bluetooth =============================

    # enable bluetooth & gui paring tools - blueman
    # or you can use cli:
    # $ bluetoothctl
    # [bluetooth] # power on
    # [bluetooth] # agent on
    # [bluetooth] # default-agent
    # [bluetooth] # scan on
    # ...put device in pairing mode and wait [hex-address] to appear here...
    # [bluetooth] # pair [hex-address]
    # [bluetooth] # connect [hex-address]
    # Bluetooth devices automatically connect with bluetoothctl as well:
    # [bluetooth] # trust [hex-address]
    hardware.bluetooth.enable = true;
    services.blueman.enable = true;

    #============================= Power =============================

    services.thermald.enable = true;
    services.power-profiles-daemon.enable = lib.mkForce false; # conflict with auto-cpufreq
    services.auto-cpufreq.enable = true; # replace tlp
    services.auto-cpufreq.settings = {
      battery = {
        governor = "powersave";
        turbo = "never";
      };
      charger = {
        governor = "performance";
        turbo = "auto";
      };
    };

    #================================= Misc =================================

    services = {
      printing.enable = true; # Enable CUPS to print documents.
      geoclue2.enable = true; # Enable geolocation services.
      udev.packages = with pkgs; [
        android-udev-rules # required by adb
      ];
    };
  };
}
