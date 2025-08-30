{...}: {
  imports = [
    # Desktop Manager
    ./kde
    ./hyprland

    # Software
    ./applications
    ./fhs
    ./gaming

    # Hardware
    ./peripherals.nix
  ];
}
