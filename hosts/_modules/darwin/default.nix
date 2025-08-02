{...}: {
  imports = [
    ./homebrew.nix
    ./nix.nix
    ./os-defaults.nix
    ./users.nix
  ];

  system = {
    stateVersion = 5;
  };
}
