{...}: {
  imports = [
    ./fonts.nix
    ./homebrew.nix
    ./nix.nix
    ./os-defaults.nix
  ];

  system = {
    stateVersion = 5; # nix-darwin stateVersion 24.11
  };
}
