{
  config,
  lib,
  ...
}: let
  cfg = config.modules.desktop;
in {
  config = lib.mkIf (cfg.manager == "kde") {
    # KDE Plasma 6, ref:https://wiki.nixos.org/wiki/KDE
    services.xserver.enable = true;
    services.displayManager.sddm = {
      enable = true;
      wayland.enable = true;
      settings.General.DisplayServer = "wayland";
    };
    services.desktopManager.plasma6.enable = true;
  };
}
