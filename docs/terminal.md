# Terminal Environment

The terminal stack: multiplexer, emulator, appearance, and input method.

## Zellij

Reference: [ryan4yin/nix-config zellij README](https://github.com/ryan4yin/nix-config/blob/main/home/base/tui/zellij/README.md)

Zellij is a terminal workspace with batteries included. At its core it is a
terminal multiplexer (like tmux or screen), but that is merely its
infrastructure layer. It is user-friendly, with a step-by-step hint system for
learning keybindings, similar to Neovim or Helix. By contrast, tmux's key design
is counterintuitive, has no prompt system, and weak plugin performance.

### Why Zellij as the default terminal environment

Zellij autostarts on shell login and the shell session exits when Zellij exits,
making it the default terminal environment:

- The terminal emulator (kitty/alacritty/wezterm/Ghostty) is reduced to
  displaying characters; search/copy/scrollback come from Zellij with one
  consistent UX across emulators.
- Emulators become interchangeable without losing functionality.
- The same workflow works locally and over SSH on any server — learn once,
  use everywhere.
- More capable and stable than embedded terminal multiplexers such as the
  Neovim integrated terminal.

### Passthrough mode (lock mode)

`Ctrl+g` locks the outer Zellij interface; all keys go to the focused pane.
Essential when:

1. Nesting: local Zellij around a remote Zellij over SSH.
2. Avoiding key conflicts with programs in the pane (vim, tmux, ...).

## Terminal emulator

- Ghostty is the standard emulator (see [decisions.md](decisions.md)).
- Theme: `catppuccin-mocha`.
- Font: `JetBrains Nerd Font Mono`, Regular.

## Chinese input method

- Schema: [rime-shuangpin-fuzhuma](https://github.com/gaboolic/rime-shuangpin-fuzhuma), primary.
- Backends: `fcitx5-rime` on Linux, Squirrel on macOS.
- When the input bar shows, `Ctrl+`` opens the control panel.
