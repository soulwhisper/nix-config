{
  config,
  lib,
  pkgs,
  ...
}: let
  ifGroupsExist = groups: builtins.filter (group: builtins.hasAttr group config.users.groups) groups;
in {
  config = {
    users.mutableUsers = false;

    # default user, 1000:1000
    users.users.soulwhisper = {
      uid = 1000;
      name = "soulwhisper";
      home = "/home/soulwhisper";
      group = "soulwhisper";
      shell = pkgs.fish;
      openssh.authorizedKeys.keys = lib.strings.splitString "\n" (builtins.readFile ../../../homes/soulwhisper/config/ssh/ssh.pub);
      hashedPasswordFile = config.sops.secrets."users/soulwhisper/password".path;
      isNormalUser = true;
      extraGroups =
        [
          "wheel"
          "users"
        ]
        ++ ifGroupsExist [
          "network"
          "samba-users"
        ];
    };
    users.groups.soulwhisper.gid = 1000;

    # appuser, 1001:1001
    users.users.appuser = {
      group = "appuser";
      uid = 1001;
      isSystemUser = true;
    };
    users.groups.appuser.gid = 1001;

    # shell for users
    system.activationScripts.postActivation.text = ''
      # Must match what is in /etc/shells
      chsh -s /run/current-system/sw/bin/fish soulwhisper
    '';
  };
}
