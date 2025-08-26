{
  config,
  lib,
  pkgs,
  ...
}: {
  config = {
    programs.ssh = {
      enable = true;
      controlMaster = "auto";
      controlPath = "~/.ssh/control/ssh-%r@%h:%p";
      includes = [
        "config.d/*"
      ];

      matchBlocks = {
        "192.168.*.*" = {
          host = "192.168.*.*";
          sendEnv = [
            "TERM=xterm-256color"
          ];
          extraOptions = {
            StrictHostKeyChecking = "no";
            UserKnownHostsFile = "/dev/null";
          };
        };
        "172.16.*.*" = {
          host = "172.16.*.*";
          sendEnv = [
            "TERM=xterm-256color"
          ];
          extraOptions = {
            StrictHostKeyChecking = "no";
            UserKnownHostsFile = "/dev/null";
          };
        };
        "10.*.*.*" = {
          host = "10.*.*.*";
          sendEnv = [
            "TERM=xterm-256color"
          ];
          extraOptions = {
            StrictHostKeyChecking = "no";
            UserKnownHostsFile = "/dev/null";
          };
        };
      };
    };
  };
}
