{...}: {
  imports = [
    ./homebrew.nix
    ./nix.nix
    ./os-defaults.nix

    # window tiling
    ./skhd.nix
    ./yabai.nix
  ];

  system = {
    stateVersion = 5;
  };
}
