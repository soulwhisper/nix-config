{
  config,
  lib,
  pkgs,
  ...
}: {
  config = {
    programs.ssh = {
      enable = true;

      matchBlocks = {
        "internal" = {
          host = "192.168.*.* 172.16.*.* 10.*.*.* *.homelab.internal";
          sendEnv = [
            "TERM=xterm-256color"
          ];
          # defaults
          forwardAgent = false;
          addKeysToAgent = "no";
          compression = false;
          serverAliveInterval = 0;
          serverAliveCountMax = 3;
          hashKnownHosts = false;
          userKnownHostsFile = "/dev/null";
          controlMaster = "auto";
          controlPath = "~/.ssh/control/ssh-%r@%h:%p";
          controlPersist = "no";
        };
      };
    };
  };
}
