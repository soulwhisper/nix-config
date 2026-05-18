{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.development.claude;

# Claude Code home-manager module — self-contained.
#
# Three concerns are wrapped together so they can never drift:
#   1. Package wrapper (auth injection + backend routing)        -> claude-code-wrapped
#   2. Settings file (managed fragment merged with CLI state)    -> home.activation.claudeSettings
#   3. Static assets (CLAUDE.md, agents/, commands/, skills/)    -> home.file (symlink to store)
#
# CLI-owned state (`enabledPlugins`, `extraKnownMarketplaces`, `installedPlugins`)
# is deliberately NOT managed here — those are owned by `just claude-bootstrap`.

  managedSettings = import ./settings.nix { inherit lib; };
  managedSettingsFile = pkgs.writeText "claude-managed-settings.json"
    (builtins.toJSON managedSettings);

  # --- wrapper run-snippet -------------------------------------------------
  # makeWrapper --run executes this shell fragment before exec'ing the real
  # claude binary. All ''${...} are Nix-string escapes — at runtime bash sees
  # plain ${...}.
  wrapperRunSnippet = ''
    # (1) AUTH_TOKEN fallback chain: env > authFile > empty (don't block --version)
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
    # (2) Backend routing: default DeepSeek, opt out via CLAUDE_USE_ANTHROPIC=1
    #     `: "''${VAR:=default}"` sets default only when unset — user env wins.
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
  # Asset directories that ship side-by-side with this module.
  assetSources = {
    "CLAUDE.md"  = ./CLAUDE.md;
    "agents"     = ./agents;
    "commands"   = ./commands;
    "skills"     = ./skills;
  };
in {
  options.modules.development.claude = {
    enable = lib.mkEnableOption "claude-code";
    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.unstable.claude-code;
    };
    authFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
    };
    installAssets = lib.mkOption {
      type    = lib.types.bool;
      default = true;
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
  };

  config = lib.mkIf cfg.enable {
    # The upstream module manages the package, wrapper, and a small set of
    # settings.json fields. We DO NOT pass `settings = ...` here — settings
    # are materialized by the activation script below instead, so that the
    # CLI can also write to the same file (plugin install would otherwise
    # hit EROFS against the Nix store).
    programs.claude-code = {
      enable = true;
      package = claude-code-wrapped;
    };

    home.packages =
      (with pkgs; [
        nodejs-slim # claude-mem
        bun         # claude-mem
      ])
      ++ (with pkgs.unstable; [
        # placeholder
      ]);

    # Static, declarative parts of ~/.claude — these are fine as store
    # symlinks because no CLI ever writes to them at runtime.
    home.file = lib.mkIf cfg.installAssets (
      lib.mapAttrs' (name: src: lib.nameValuePair ".claude/${name}" { source = src; })
        assetSources
    );

    # Activation: render settings.json as a real, writable file by merging
    # our managed fragment over whatever the CLI has accumulated. CLI-owned
    # keys are explicitly stripped from the managed side so we can never
    # clobber `enabledPlugins`, `extraKnownMarketplaces`, `installedPlugins`.
    home.activation.claudeSettings =
      lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        $DRY_RUN_CMD install -d "$HOME/.claude"
        target="$HOME/.claude/settings.json"

        # If a previous generation left a store symlink, drop it.
        if [ -L "$target" ]; then
          $DRY_RUN_CMD rm -f "$target"
        fi

        managed=${managedSettingsFile}
        current_json='{}'
        if [ -s "$target" ]; then
          current_json="$(${pkgs.jq}/bin/jq -c '.' "$target" 2>/dev/null || echo '{}')"
        fi

        # Merge: managed * current — managed wins on conflict, but we first
        # delete CLI-owned keys from `managed` so they can never be touched.
        merged="$(
          ${pkgs.jq}/bin/jq -n --slurpfile m "$managed" --argjson c "$current_json" '
            ($m[0]
              | del(.enabledPlugins, .extraKnownMarketplaces, .installedPlugins))
            as $managed
            | $c * $managed
          '
        )"

        $DRY_RUN_CMD printf '%s\n' "$merged" > "$target.tmp"
        $DRY_RUN_CMD ${pkgs.jq}/bin/jq '.' "$target.tmp" > "$target"
        $DRY_RUN_CMD rm -f "$target.tmp"
        $DRY_RUN_CMD chmod 0644 "$target"
      '';
  };
}
