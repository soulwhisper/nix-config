{pkgs, ...}: let
  jq = "${pkgs.jq}/bin/jq";
  yabai = "${pkgs.yabai}/bin/yabai";
  xargs = "${pkgs.coreutils}/bin/xargs";
in {
  # https://github.com/koekeishiya/yabai/wiki
  services.yabai = {
    enable = true;
    config = {
      layout = "bsp";
      split_ratio = "0.5";
      split_type = "auto";
      auto_balance = "off";
      window_zoom_persist = "on";
      window_placement = "second_child";
      top_padding = "15";
      bottom_padding = "15";
      left_padding = "15";
      right_padding = "15";
      window_gap = "10";
      window_shadow = "off";
      window_opacity = "off";
      window_opacity_duration = "0.0";
      active_window_opacity = "1.0";
      normal_window_opacity = "0.8";
      mouse_drop_action = "swap";
      mouse_modifier = "shift";
      mouse_action1 = "move";
      mouse_action2 = "resize";
    };
    extraConfig = ''
      ${yabai} -m rule --add app="^Calculator$" manage=off
      ${yabai} -m rule --add app="^System Settings$" manage=off
      ${yabai} -m rule --add app="^Software Update$" manage=off
      ${yabai} -m rule --add label="Finder" app="^Finder$" title="(Copy|Connect|Move|Info|Pref)" manage=off

      ${yabai} -m signal --add event=space_created action='
        prev_space=$(${yabai} -m query --spaces --space)
        new_space=$(${yabai} -m query --spaces --space "$YABAI_SPACE_INDEX")
        space_id=$(${jq} -e "select(.\"is-native-fullscreen\") | .id" <<< "$new_space") || exit
        json_space=$(${jq} "{ id: $space_id, homeSpace: .id } | tojson" <<< "$prev_space")
        label=$(${jq} -Rr "ltrimstr(\"\\\"\") | rtrimstr(\"\\\"\")" <<< "$json_space")
        ${yabai} -m space "$YABAI_SPACE_INDEX" --label "$label"
      '

      ${yabai} -m signal --add event=window_destroyed action='
        current_space=$(${yabai} -m query --spaces --space | ${jq} .index)
        recent_window=$( \
          ${yabai} -m query --windows | ${jq} -e "
            map(
              select(.space == $current_space)
              | select(.\"is-hidden\" | not)
              | .id
            )
            | .[0]
          " \
        ) || exit
        ${yabai} -m window --focus "$recent_window" || exit
      '

      ${yabai} -m signal --add event=space_changed action='
        home_spaces=$(${yabai} -m query --spaces | ${jq} "map(.label | try fromjson | .homeSpace // empty)")
        hidden_windows=$(${yabai} -m query --windows | ${jq} "map(select(.\"is-hidden\") | .id)")
        ${yabai} -m query --spaces \
        | ${jq} "
            map(
              select(
                .windows
                | map(select(. as \$x | $hidden_windows | index(\$x) | not))
                | length == 0
              )
              | select(.\"has-focus\" | not)
              | select(.id as \$x | $home_spaces | index(\$x) | not)
            )
            | reverse
            | .[]
            | .index
        " \
        | ${xargs} -I{} ${yabai} -m space --destroy {}
      '
    '';
  };
}
