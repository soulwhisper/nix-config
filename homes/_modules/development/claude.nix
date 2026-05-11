{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.development;

  wrapperRunSnippet = ''
    if [ -z "''${ANTHROPIC_AUTH_TOKEN:-}" ] && [ -z "''${ANTHROPIC_API_KEY:-}" ]; then
    ${optionalString (cfg.authFile != null) ''
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
in {
  options.modules.development = {
    claude.authFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
    };
    claude.backend = mkOption {
      default = {};
      type = types.submodule {
        options = {
          baseUrl       = mkOption { type = types.str; default = "https://api.deepseek.com/anthropic"; };
          model         = mkOption { type = types.str; default = "deepseek-v4-pro[1m]"; };
          opusModel     = mkOption { type = types.str; default = "deepseek-v4-pro[1m]"; };
          sonnetModel   = mkOption { type = types.str; default = "deepseek-v4-pro"; };
          haikuModel    = mkOption { type = types.str; default = "deepseek-v4-flash"; };
          subagentModel = mkOption { type = types.str; default = "deepseek-v4-flash"; };
        };
      };
    };
    claude.package = lib.mkOption {
      type = types.package;
      default = pkgs.unstable.claude-code;
    };
  };

  config = lib.mkIf cfg.enable {
    programs.claude-code = {
      enable = true;
      package = claude-code-wrapped;
      settings = {
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
            "Bash(git push:*)" "Bash(sudo:*)"
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
    };
  };
}
