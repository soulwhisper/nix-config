{pkgs, ...}: {
  config = {
    catppuccin.starship.enable = true;
    programs.starship = {
      enable = true;
      package = pkgs.unstable.starship;

      settings = {
        format = ''
          $os$time$username($hostname)($kubernetes)($git_branch)($python)($golang)($terraform)
          $directory$character
        '';

        os = {
          disabled = false;
          symbols.Macos = "";
          symbols.NixOS = "";
          style = "bg:blue fg:base";
          format = "[ $symbol]($style)";
        };

        time = {
          disabled = false;
          time_format = "%R"; # Hour:Minute Format
          style = "bg:blue fg:base bold";
          format = "[  $time [](fg:blue bg:peach)]($style)";
        };

        username = {
          disabled = false;
          show_always = true;
          style_user = "bg:peach fg:base bold";
          style_root = "bg:peach fg:base bold";
          format = "[ $user [](fg:peach bg:base)]($style)";
        };

        hostname = {
          disabled = false;
          ssh_only = false;
          ssh_symbol = "🌏";
          style = "bg:maroon fg:base bold";
          format = "[ $ssh_symbol $hostname [](fg:maroon bg:base)]($style)";
        };

        git_branch = {
          symbol = "  ";
          style = " bg:yellow fg:base";
          format = "[ $symbol$branch(:$remote_branch) [](fg:yellow bg:base)]($style)";
        };

        kubernetes = {
          disabled = false;
          symbol = "☸️ ";
          style = "bg:green fg:base";
          format = "[ $symbol$context \\($namespace\\) [](fg:green bg:base)]($style)";
        };

        python = {
          symbol = "🐍 ";
          style = "bg:flamingo fg:base";
          format = "[ $symbol$pyenv_prefix($version )(\\($virtualenv\\)) [](fg:flamingo bg:base)]($style)";
        };

        golang = {
          symbol = "🐹 ";
          style = "bg:flamingo fg:base";
          format = "[ $symbol($version) [](fg:flamingo bg:base)]($style)";
        };

        terraform = {
          symbol = "🛠️ ";
          style = "bg:flamingo fg:base";
          format = "[ $symbol$version [](fg:flamingo bg:base)]($style)";
        };

        directory = {
          truncation_length = 4;
          truncation_symbol = "…/";
          style = "fg:lavender";
          format = "[  $path]($style)";
        };

        character = {
          success_symbol = "[ >](bold green)";
          error_symbol = "[ ✗](#E84D44)";
        };
      };
    };
  };
}
