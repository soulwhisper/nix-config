_: {
  nix.gc = {
    interval = {
      Weekday = 0;
      Hour = 3;
      Minute = 0;
    };
  };

  # Route daemon fetches through the local proxy; clash TUN fake-ip breaks TLS.
  # Persists what bootstrap/darwin_set_proxy.py does manually.
  launchd.daemons.nix-daemon.serviceConfig.EnvironmentVariables = {
    http_proxy = "http://127.0.0.1:1080";
    https_proxy = "http://127.0.0.1:1080";
  };
}
