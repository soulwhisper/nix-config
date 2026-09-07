{
  config,
  lib,
  pkgs,
  ...
}:
{
  modules = {
    kubernetes.enable = true;
    security._1password-cli.enable = true;
  };

  # HM activation runs under `sudo -u` with a sanitized env, so shell proxy
  # exports never reach it; krew's index fetch needs this when clash TUN is up.
  programs.git.settings.http.proxy = "http://127.0.0.1:1080";

  # clash-verge runs without admin: no TUN, no system proxy. Only env-var
  # proxy works, so export it for every shell (fish sources hm-session-vars).
  home.sessionVariables = {
    http_proxy = "http://127.0.0.1:1080";
    https_proxy = "http://127.0.0.1:1080";
    all_proxy = "http://127.0.0.1:1080";
    no_proxy = ".noirprime.com,.homelab.internal,localhost,127.0.0.0/8,::1,10.0.0.0/8,172.16.0.0/12,192.168.0.0/16";
  };
}
