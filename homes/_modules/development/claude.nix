{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.development.claude;

  wrapperRunSnippet = ''
    if [ -z "''${ANTHROPIC_AUTH_TOKEN:-}" ] && [ -z "''${ANTHROPIC_API_KEY:-}" ]; then
    ${lib.optionalString (cfg.authFile != null) ''
      if [ -r "${cfg.authFile}" ]; then
        _tok="$(tr -d '[:space:]' < "${cfg.authFile}")"
        if [ -n "$_tok" ]; then
          export ANTHROPIC_AUTH_TOKEN="$_tok"
        else
          printf '[claude] auth file %s empty; launching without token\n' "${cfg.authFile}" >&2
        fi
        unset _tok
      else
        printf '[claude] auth file %s not readable; launching without token\n' "${cfg.authFile}" >&2
      fi
    ''}
    fi

    if [ "''${CLAUDE_USE_ANTHROPIC:-0}" != "1" ]; then
      : "''${ANTHROPIC_BASE_URL:=${cfg.backend.baseUrl}}"
      : "''${ANTHROPIC_MODEL:=${cfg.backend.model}}"
      : "''${ANTHROPIC_DEFAULT_OPUS_MODEL:=${cfg.backend.opusModel}}"
      : "''${ANTHROPIC_DEFAULT_SONNET_MODEL:=${cfg.backend.sonnetModel}}"
      : "''${ANTHROPIC_DEFAULT_HAIKU_MODEL:=${cfg.backend.haikuModel}}"
      : "''${CLAUDE_CODE_SUBAGENT_MODEL:=${cfg.backend.subagentModel}}"
      export ANTHROPIC_BASE_URL ANTHROPIC_MODEL \
             ANTHROPIC_DEFAULT_OPUS_MODEL \
             ANTHROPIC_DEFAULT_SONNET_MODEL \
             ANTHROPIC_DEFAULT_HAIKU_MODEL \
             CLAUDE_CODE_SUBAGENT_MODEL
    fi
  '';
  claude-code-wrapped = pkgs.symlinkJoin {
    name = "claude-code-wrapped";
    paths = [ cfg.package ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/claude --run ${lib.escapeShellArg wrapperRunSnippet}
    '';
    inherit (cfg.package) meta;
  };

  managedSettings = {
    env = {
      CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC = "1";
      CLAUDE_CODE_DISABLE_NONSTREAMING_FALLBACK = "1";
      CLAUDE_CODE_EFFORT_LEVEL = "max";
    };
    includeCoAuthoredBy = false;
    permissions = {
      deny = [
        "Read(./**/*.sops.*)"
        "Read(./**/secrets.sops.yaml)"
        "Read(~/.config/age/**)"
        "Read(~/.config/sops/**)"
        "Bash(sops:*)"
      ];
      ask = [
        "Bash(git push:*)"
        "Bash(sudo:*)"
        "Bash(darwin-rebuild:*)"
        "Bash(nixos-rebuild:*)"
      ];
      allow = [
        "Bash(just:*)"
        "Bash(prek:*)"
        "Bash(nix build:*)"
        "Bash(nix flake check:*)"
        "Bash(git diff:*)"
        "Bash(git status:*)"
        "Bash(git log:*)"
        "Edit"
      ];
    };
    hooks.PostToolUse = [{
      matcher = "Edit|MultiEdit|Write";
      hooks = [{
        type = "command";
        command = ''
          f=$(jq -r '.tool_input.file_path' <<< "$CLAUDE_TOOL_INPUT")
          case "$f" in *.nix) nixfmt "$f" ;; esac
        '';
      }];
    }];
  };
  managedJson = pkgs.writeText "claude-managed-settings.json"
    (builtins.toJSON managedSettings);
in {
  options.modules.development.claude = {
    enable = lib.mkEnableOption "claude-code";
    authFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
    };
    backend = lib.mkOption {
      default = {};
      type = lib.types.submodule {
        options = {
          baseUrl       = lib.mkOption { type = lib.types.str; default = "https://api.deepseek.com/anthropic"; };
          model         = lib.mkOption { type = lib.types.str; default = "deepseek-v4-pro[1m]"; };
          opusModel     = lib.mkOption { type = lib.types.str; default = "deepseek-v4-pro[1m]"; };
          sonnetModel   = lib.mkOption { type = lib.types.str; default = "deepseek-v4-pro"; };
          haikuModel    = lib.mkOption { type = lib.types.str; default = "deepseek-v4-flash"; };
          subagentModel = lib.mkOption { type = lib.types.str; default = "deepseek-v4-flash"; };
        };
      };
    };
    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.unstable.claude-code;
    };
    mcp.authFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
    };
  };

  config = lib.mkIf cfg.enable {
    programs.claude-code = {
      enable = true;
      package = claude-code-wrapped;
    };

    home.activation.claudeSettingsMerge =
      lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        set -euo pipefail
        TARGET="$HOME/.claude/settings.json"
        MANAGED='${managedJson}'
        JQ='${pkgs.jq}/bin/jq'
        mkdir -p "$HOME/.claude"
        if [ -L "$TARGET" ]; then
          rm "$TARGET"
        fi
        if [ -s "$TARGET" ]; then
          CURRENT=$(cat "$TARGET")
        else
          CURRENT='{}'
        fi
        "$JQ" -n \
          --argjson current "$CURRENT" \
          --slurpfile managed "$MANAGED" \
          '($managed[0] | del(.enabledPlugins, .extraKnownMarketplaces, .installedPlugins)) as $m
           | $current * $m' \
          > "$TARGET.tmp"
        mv "$TARGET.tmp" "$TARGET"
        chmod 0644 "$TARGET"
      '';
  };
}
