{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (config.home) username homeDirectory;
  hasPackage = pname:
    lib.any (p: p ? pname && p.pname == pname) config.home.packages;
  hasAnyNixShell = hasPackage "any-nix-shell";
in {
  config = {
    catppuccin.fish.enable = true;
    programs.fish = {
      enable = true;
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
        ''
        + (
          if hasAnyNixShell
          then ''
            any-nix-shell fish --info-right | source
          ''
          else ""
        );
    };
    home.sessionVariables.fish_greeting = "";
    programs.nix-index.enable = true;
    programs.fish = {
      functions = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
        flushdns = {
          description = "Flush DNS cache";
          body = builtins.readFile ./functions/flushdns.fish;
        };
      };
    };
  };
}
