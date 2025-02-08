_: {
  config = {
    programs.eza.enable = true;
    programs.bash.shellAliases = {
      eza = "eza --icons auto --all --long --group --group --header --total-size";
    };
    programs.fish.shellAliases = {
      eza = "eza --icons auto --all --long --group --group --header --total-size";
    };
  };
}
