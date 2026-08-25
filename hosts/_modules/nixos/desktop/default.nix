{ ... }: {
  imports = [
    ./base.nix
    ./environments/hyprland.nix
    ./environments/niri.nix
    ./input-method.nix
    ./applications.nix
    ./fhs.nix
    ./gaming.nix
  ];
}
