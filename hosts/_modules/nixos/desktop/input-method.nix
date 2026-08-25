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
  config = lib.mkIf cfg.enable {
    # : Input method — fcitx5 + Rime (Moqi Yinxing)
    # Rime schema config is shipped by home-manager:
    # homes/_modules/customization -> ~/.local/share/fcitx5/rime
    i18n.inputMethod = {
      enable = true;
      type = "fcitx5";
      fcitx5.addons = with pkgs; [
        fcitx5-rime
        qt6Packages.fcitx5-configtool
      ];
    };
  };
}
