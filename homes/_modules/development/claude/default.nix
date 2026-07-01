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
  #   2. Settings file (managed fragment merged with CLI state)    -> home.activation.claudeSetup
  #   3. Static assets (CLAUDE.md, agents/, commands/, skills/)    -> home.activation.claudeSetup
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
    # (2) Backend routing:
    #     - CLAUDE_USE_ANTHROPIC=1       -> Official Anthropic (do nothing)
    #     - ANTHROPIC_BASE_URL is set    -> 3rd-party gateway (respect user env completely)
    #     - Neither is set               -> Default to Nix-managed DeepSeek backend
    #     `: "''${VAR:=default}"` sets default only when unset — user env wins.
    if [ "''${CLAUDE_USE_ANTHROPIC:-0}" != "1" ]; then
      if [ -z "''${ANTHROPIC_BASE_URL:-}" ]; then
        # [Case 1] default deepseek backend
        export ANTHROPIC_BASE_URL="${cfg.backend.baseUrl}"
        export ANTHROPIC_MODEL="${cfg.backend.model}"
        export ANTHROPIC_DEFAULT_OPUS_MODEL="${cfg.backend.opusModel}"
        export ANTHROPIC_DEFAULT_SONNET_MODEL="${cfg.backend.sonnetModel}"
        export ANTHROPIC_DEFAULT_HAIKU_MODEL="${cfg.backend.haikuModel}"
        export CLAUDE_CODE_SUBAGENT_MODEL="${cfg.backend.subagentModel}"
        export CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1
      else
        # [Case 2] 3rd-party gateway backend
        : "''${CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC:=1}"
      fi
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

    home.activation.claudeSetup =
      lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        # Bootstrap ~/.claude. Runs on every `home-manager switch`.
        #
        # (a) settings.json — managed fragment merged over CLI-accumulated
        #     state, materialized as a real writable file (the CLI must be
        #     able to keep appending plugin/marketplace state at runtime).
        #     CLI-owned keys are del()'d from the managed side so we can
        #     never clobber them.
        #
        # (b) Static assets — CLAUDE.md, agents/, commands/, skills/.
        #     Seed-on-absent: missing paths get copied from the Nix store,
        #     existing local files (debug edits, hand-rolled skills) are
        #     preserved across rebuilds.
        #
        # Both halves first unlink any store symlink left by a previous
        # generation so the path becomes writable.

        $DRY_RUN_CMD install -d "$HOME/.claude"

        # Drop a stale store symlink at $1, if any Real files are kept.
        _unwrap_link() {
          if [ -L "$1" ]; then
            $DRY_RUN_CMD rm -f "$1"
          fi
        }

        # Seed src -> dst when dst is missing. Handles both files and
        # directories: directories are walked per-file so newly-shipped
        # entries land while existing locals are untouched.
        _seed() {
          local src="$1" dst="$2"
          _unwrap_link "$dst"
          if [ -d "$src" ]; then
            $DRY_RUN_CMD install -d "$dst"
            while IFS= read -r -d "" rel; do
              rel="''${rel#./}"
              local file="$dst/$rel"
              if [ ! -e "$file" ]; then
                $DRY_RUN_CMD install -D -m 0644 "$src/$rel" "$file"
              fi
            done < <(cd "$src" && find . -type f -print0)
          elif [ ! -e "$dst" ]; then
            $DRY_RUN_CMD install -D -m 0644 "$src" "$dst"
          fi
        }

        # ---- (a) settings.json ---------------------------------------------
        target="$HOME/.claude/settings.json"
        _unwrap_link "$target"

        # Snapshot the on-disk state. Missing / empty / unparseable -> {}.
        current_json='{}'
        if [ -s "$target" ]; then
          current_json="$(${pkgs.jq}/bin/jq -c '.' "$target" 2>/dev/null || echo '{}')"
        fi

        # current * managed  (managed wins), with CLI-owned keys stripped
        # from managed beforehand. Write atomically via tmp + mv so a jq
        # failure under `set -e` leaves the live file intact.
        $DRY_RUN_CMD ${pkgs.jq}/bin/jq -n \
          --slurpfile m ${managedSettingsFile} \
          --argjson c "$current_json" '
            ($m[0]
              | del(.enabledPlugins, .extraKnownMarketplaces, .installedPlugins))
            as $managed
            | $c * $managed
          ' > "$target.tmp"
        $DRY_RUN_CMD mv "$target.tmp" "$target"
        $DRY_RUN_CMD chmod 0644 "$target"

        # ---- (b) static assets ---------------------------------------------
        _seed ${./CLAUDE.md} "$HOME/.claude/CLAUDE.md"
        _seed ${./agents}    "$HOME/.claude/agents"
        _seed ${./commands}  "$HOME/.claude/commands"
        _seed ${./skills}    "$HOME/.claude/skills"
      '';
  };
}
