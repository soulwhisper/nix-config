{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.desktop;
in
{
  options.modules.desktop = {
    enable = lib.mkEnableOption "desktop";

    environment = lib.mkOption {
      type = lib.types.enum [ "niri" ];
      default = "niri";
      description = "Window-manager / session choice.";
    };
  };

  config = lib.mkIf cfg.enable {
    # : NetworkManager replaces networkd on desktops
    # (base sets `useNetworkd`/`systemd.network.enable` via mkDefault)
    networking = {
      networkmanager.enable = true;
      useNetworkd = false;
    };
    systemd.network.enable = false;

    # : Audio — PipeWire stack
    services.pulseaudio.enable = false;
    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;
      wireplumber.enable = true;
    };

    # : Bluetooth
    hardware.bluetooth.enable = true;
    services.blueman.enable = true;

    # : Firmware updates, disk mounting
    services.fwupd.enable = true;
    services.gvfs.enable = true;
    services.udisks2.enable = true;

    # : Peripherals
    services.printing.enable = true; # CUPS
    services.geoclue2.enable = true;
    fonts.packages = with pkgs; [
      lxgw-neoxihei
      nerd-fonts.jetbrains-mono
      noto-fonts-color-emoji
    ];

    # : Seat groups for the desktop user
    # Guarded: only groups that actually exist in this evaluation.
    users.users.soulwhisper.extraGroups = lib.filter (g: builtins.hasAttr g config.users.groups) [
      "video"
      "audio"
      "input"
      "networkmanager"
    ];
  };
}
