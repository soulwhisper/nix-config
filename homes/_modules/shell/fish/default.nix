{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (config.home) username homeDirectory;
in {
  config = {
    catppuccin.fish.enable = true;
    programs.fish = {
      enable = true;
      functions =  {
        flushdns = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
          description = "Flush MacOS DNS cache";
          body = builtins.readFile ./functions/flushdns.fish;
        };
      };
      plugins = [
        {
          name = "done";
          inherit (pkgs.fishPlugins.done) src;
        }
        {
          name = "fzf";
          inherit (pkgs.fishPlugins.fzf-fish) src;
        }
        {
          name = "puffer";
          inherit (pkgs.fishPlugins.puffer) src;
        }
        {
          name = "zoxide";
          src = pkgs.fetchFromGitHub {
            owner = "kidonng";
            repo = "zoxide.fish";
            rev = "bfd5947bcc7cd01beb23c6a40ca9807c174bba0e";
            sha256 = "Hq9UXB99kmbWKUVFDeJL790P8ek+xZR5LDvS+Qih+N4=";
          };
        }
      ];
      interactiveShellInit =
        ''
          function remove_path
            if set -l index (contains -i $argv[1] $PATH)
               set --erase --universal fish_user_paths[$index]
           end
          end

          function update_path
            if test -d $argv[1]
              fish_add_path -m $argv[1]
            else
              remove_path $argv[1]
            end
          end

          # Paths are in reverse priority order
          update_path /opt/homebrew/bin
          update_path ${homeDirectory}/.krew/bin
          update_path /nix/var/nix/profiles/default/bin
          update_path /run/current-system/sw/bin
          update_path /etc/profiles/per-user/${username}/bin
          update_path /run/wrappers/bin
          update_path ${homeDirectory}/go/bin
          update_path ${homeDirectory}/.cargo/bin
          update_path ${homeDirectory}/.local/bin

          any-nix-shell fish --info-right | source
        '';
    };
    home.sessionVariables.fish_greeting = "";
    programs.nix-index.enable = true;
    programs.zoxide.enable = true;
  };
}
