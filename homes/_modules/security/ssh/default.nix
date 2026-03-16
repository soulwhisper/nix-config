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
        "*" = {
          # defaults
          forwardAgent = false;
          addKeysToAgent = "no";
          compression = false;
          serverAliveInterval = 0;
          serverAliveCountMax = 3;
          hashKnownHosts = false;
          userKnownHostsFile = "~/.ssh/known_hosts";
          controlMaster = "no";
          controlPath = "~/.ssh/control/ssh-%r@%h:%p";
          controlPersist = "no";
        };
      };
    };
  };
}
