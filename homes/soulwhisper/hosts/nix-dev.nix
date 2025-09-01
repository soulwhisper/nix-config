{
  lib,
  pkgs,
  ...
}: {
  modules = {
    development.enable = true;
    # hyprland.enable = true;
    kubernetes.enable = true;
    security._1password-cli.enable = true;
  };

  # : Nvidia Support
  # : ref:https://wiki.hyprland.org/Nvidia/
  home.sessionVariables = {
    "LIBVA_DRIVER_NAME" = "nvidia";
    "__GLX_VENDOR_LIBRARY_NAME" = "nvidia";
    "NVD_BACKEND" = "direct";
    "GBM_BACKEND" = "nvidia-drm";
  };
}
