{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (config.home) username homeDirectory;
in {
  config = {
    programs.ssh = {
      enable = true;
      controlMaster = "auto";
      controlPath = "~/.ssh/control/ssh-%r@%h:%p";
      includes = [
        "config.d/*"
      ];
      extraConfig = ''
        PermitLocalCommand yes
        LocalCommand ssh_pwd_update %h
      '';

      matchBlocks = {
        "192.168.*.*" = {
          host = "192.168.*.*";
          extraOptions = {
            StrictHostKeyChecking = "no";
            UserKnownHostsFile = "/dev/null";
          };
        };
        "172.16.*.*" = {
          host = "172.16.*.*";
          extraOptions = {
            StrictHostKeyChecking = "no";
            UserKnownHostsFile = "/dev/null";
          };
        };
        "10.*.*.*" = {
          host = "10.*.*.*";
          extraOptions = {
            StrictHostKeyChecking = "no";
            UserKnownHostsFile = "/dev/null";
          };
        };
      };
    };

    programs.fish = {
      functions = {
        ssh_pwd_update = {
          description = "ssh host dir hack";
          body = ''
            if test (count $argv) -ne 1
              echo "Error: For usage from ssh_config only" >&2
              return 1
            end
            set host $argv[1]
            set -l ssh_pwd_dir "${homeDirectory}/.ssh/hosts/$host"
            mkdir -p "$ssh_pwd_dir"
            printf '\e]7;%s\a' "file://localhost$ssh_pwd_dir" >> /dev/tty
          '';
        };
      };
      interactiveShellInit = ''
        function __check_ssh_pwd_dir --on-variable PWD
          set -l ssh_pwd_pre "${homeDirectory}/.ssh/hosts"
          if string match -q -- "$ssh_pwd_pre/*" $PWD
            set -l host (string replace "$ssh_pwd_pre/" "" -- $PWD | cut -d/ -f1)
            echo -n "SSH to $host? [Y/n] "
            read -l response
            if test -z "$response" -o "$response" != "n"
              echo "Connecting to $host..."
              exec ssh $host
            else
              cd ${homeDirectory}
            end
          end
        end
      ''
    };
  };
}
