{
  pkgs,
  config,
  ...
}: {
  # ref:https://github.com/grimerssy/dotfiles/blob/main/modules/darwin/configurations/skhd.nix
  services.skhd = {
    enable = true;
    skhdConfig = ''
      rctrl - b : ${config.services.yabai.package}/bin/yabai -m space --balance
      rctrl - v : ${config.services.yabai.package}/bin/yabai -m window --toggle split
      rctrl - s : ${config.services.yabai.package}/bin/yabai -m window --toggle sticky
      rctrl - m : ${config.services.yabai.package}/bin/yabai -m space --toggle mission-control
    '';
  };
}
