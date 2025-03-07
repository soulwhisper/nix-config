_: {
  nix.gc = {
    interval = {
      Weekday = 0;
      Hour = 3;
      Minute = 0;
    };
  };

  services.nix-daemon.enable = true;
}
