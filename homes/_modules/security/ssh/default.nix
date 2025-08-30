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
        "internal" = {
          host = "192.168.*.* 172.16.*.* 10.*.*.* *.homelab.internal";
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
