set lazy
set quiet
set script-interpreter := ['bash', '-euo', 'pipefail']
set shell := ['bash', '-euo', 'pipefail', '-c']
set positional-arguments

export DEPLOYMENT_REPO := invocation_directory()

[private]
default:
  @just --list

[doc('Build pinned clean revision locally or with explicit --builder (never defaults to target)')]
[script]
build HOST REVISION *OPTIONS:
  nix run "$DEPLOYMENT_REPO#deployment-tools" -- build --repo "$DEPLOYMENT_REPO" --host "$1" --revision "$2" "${@:3}"

[doc('Plan pinned closure against target baseline; PLAN must be outside clean repository')]
[script]
plan HOST TARGET REVISION SYSTEM PLAN:
  nix run "$DEPLOYMENT_REPO#deployment-tools" -- plan --repo "$DEPLOYMENT_REPO" --host "$1" --target "$2" --revision "$3" --system "$4" --out "$5"

[doc('Copy exact planned closure with action-bound approval')]
[script]
copy PLAN APPROVAL:
  nix run "$DEPLOYMENT_REPO#deployment-tools" -- copy --plan "$1" --approve "$2"

[doc('Show real closure diff without activation')]
[script]
diff PLAN:
  nix run "$DEPLOYMENT_REPO#deployment-tools" -- diff --plan "$1"

[doc('Copy, diff and activate planned target with explicit deploy approval')]
[script]
deploy PLAN APPROVAL:
  nix run "$DEPLOYMENT_REPO#deployment-tools" -- deploy --plan "$1" --approve "$2"

[doc('Diff and switch target to already-copied planned closure with explicit approval')]
[script]
switch PLAN APPROVAL:
  nix run "$DEPLOYMENT_REPO#deployment-tools" -- activate --plan "$1" --approve "$2"

[doc('Read target system profile and generations (strict SSH host key checks)')]
[script]
status TARGET:
  nix run "$DEPLOYMENT_REPO#deployment-tools" -- status --target "$1"

[doc('Restore exact pre-deploy profile with separate rollback approval')]
[script]
rollback PLAN APPROVAL:
  nix run "$DEPLOYMENT_REPO#deployment-tools" -- rollback --plan "$1" --approve "$2"
