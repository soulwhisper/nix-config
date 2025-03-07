{...}: {
  imports = [
    ./fonts.nix
    ./homebrew.nix
    ./nix.nix
    ./os-defaults.nix
  ];

  system = {
    stateVersion = 5;
  };
}
