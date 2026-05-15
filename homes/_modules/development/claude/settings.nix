{ lib, ... }:
#
# Managed slice of ~/.claude/settings.json — owned by Nix, merged over CLI
# state on every home-manager switch. Anything that should react to user
# changes at runtime (plugin installs, marketplace adds) MUST NOT live here.
#
{
  # ---- runtime env (kept here only when not safe to forget across hosts) -
  # NOTE: routing (ANTHROPIC_BASE_URL/MODEL) lives in the wrapper, NOT here,
  # so `settings.json` never contains the upstream endpoint or model name.
  env = {
    CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC = "1";
    CLAUDE_CODE_DISABLE_NONSTREAMING_FALLBACK = "1";
    CLAUDE_CODE_EFFORT_LEVEL = "max";
  };

  includeCoAuthoredBy = false;
  theme = "dark";

  # ---- permissions: secrets are hard-denied; mutating commands need ack --
  permissions = {
    deny = [
      # sops / age secret material — never let Claude open these
      "Read(./**/*.sops.yaml)"
      "Read(./**/*.sops.json)"
      "Read(./**/secrets.sops.*)"
      "Read(./**/*.age)"
      "Read(~/.config/age/**)"
      "Read(~/.config/sops/**)"
      "Read(/run/user/*/secrets/**)"
      "Bash(sops:*)"
      # kubeconfig / talosconfig — read explicitly when needed, not by default
      "Read(~/.kube/config)"
      "Read(~/.talos/config)"
    ];

    ask = [
      # destructive or globally-impactful commands always confirm
      "Bash(git push:*)"
      "Bash(sudo:*)"
      "Bash(darwin-rebuild:*)"
      "Bash(nixos-rebuild:*)"
      "Bash(nix-collect-garbage:*)"
      "Bash(rm -rf:*)"
      "Bash(kubectl delete:*)"
      "Bash(kubectl apply:*)"
      "Bash(talosctl reset:*)"
      "Bash(talosctl upgrade:*)"
      "Bash(helm uninstall:*)"
      "Bash(helm upgrade:*)"
    ];

    allow = [
      # read-only / idempotent / explicitly safe
      "Bash(just:*)"
      "Bash(prek:*)"
      "Bash(nix build:*)"
      "Bash(nix flake check:*)"
      "Bash(nix flake show:*)"
      "Bash(nix eval:*)"
      "Bash(nix repl:*)"
      "Bash(git diff:*)"
      "Bash(git status:*)"
      "Bash(git log:*)"
      "Bash(git show:*)"
      "Bash(kubectl get:*)"
      "Bash(kubectl describe:*)"
      "Bash(kubectl logs:*)"
      "Bash(kubectl diff:*)"
      "Bash(talosctl get:*)"
      "Bash(talosctl version:*)"
      "Bash(helm list:*)"
      "Bash(helm diff:*)"
      "Edit"
    ];
  };

  # ---- hooks: auto-format Nix on write -----------------------------------
  hooks.PostToolUse = [
    {
      matcher = "Edit|MultiEdit|Write";
      hooks = [
        {
          type = "command";
          command = ''
            f=$(jq -r '.tool_input.file_path' <<< "$CLAUDE_TOOL_INPUT")
            case "$f" in
              *.nix)  command -v nixfmt >/dev/null && nixfmt "$f" ;;
              *.sh)   command -v shfmt  >/dev/null && shfmt -w "$f" ;;
            esac
          '';
        }
      ];
    }
  ];

  # ---- statusline: terse, infra-aware ------------------------------------
  statusLine = {
    type = "command";
    command = ''
      printf '%s' "$(basename "$PWD")"
      [ -n "$ANTHROPIC_BASE_URL" ] && [ "$ANTHROPIC_BASE_URL" != "https://api.anthropic.com" ] \
        && printf ' [%s]' "''${ANTHROPIC_MODEL:-?}"
      ctx="$(kubectl config current-context 2>/dev/null || true)"
      [ -n "$ctx" ] && printf ' ⎈ %s' "$ctx"
    '';
  };
}
