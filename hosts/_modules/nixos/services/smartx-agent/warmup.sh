# shellcheck shell=bash
set -euo pipefail

iso="${SMARTX_AGENT_ISO:-/mnt/iso}"
dst="${SMARTX_AGENT_STATE_DIR:-/var/lib/smartx-agent}"
link="${SMARTX_AGENT_LINK:-/opt/svt}"

install -d -m 0700 "$dst" "$dst/run"

# The vendor agent and HCI both expect /opt/svt. Keep the real files in
# /var/lib/smartx-agent and expose them through this symlink.
install -d -m 0755 "$(dirname "$link")"
if [ -e "$link" ] && [ ! -L "$link" ]; then
  echo "smartx-agent: $link exists and is not a symlink" >&2
  exit 1
fi
ln -sfn "$dst" "$link"

installer=""
source_id=""
src=""

if [ -f "$iso/qemu-ga" ] && [ -f "$iso/VERSION" ]; then
  # /mnt/iso already contains an extracted payload.
  src="$iso"
  source_id="payload:$(sha256sum "$iso/qemu-ga" | cut -d' ' -f1)"
elif [ -d "$iso" ]; then
  installer="$(find "$iso/" -maxdepth 1 -type f -iname 'SMTX*INSTALL*.sh' -print -quit 2>/dev/null || true)"
  if [ -z "$installer" ]; then
    # 8.3 names are truncated when the ISO is mounted without Joliet.
    installer="$(find "$iso/" -maxdepth 1 -type f -iname 'SMTX*.sh' -print -quit 2>/dev/null || true)"
  fi
  if [ -n "$installer" ]; then
    source_id="installer:$(sha256sum "$installer" | cut -d' ' -f1)"
  fi
fi

if [ -x "$dst/qemu-ga" ] && [ -f "$dst/VERSION" ] &&
  [ -n "$source_id" ] &&
  [ "$(cat "$dst/.source-id" 2>/dev/null || true)" = "$source_id" ]; then
  exit 0
fi

if [ -z "$source_id" ]; then
  if [ -x "$dst/qemu-ga" ] && [ -f "$dst/VERSION" ]; then
    echo "smartx-agent: $iso is unavailable; keeping the warmed agent in $dst" >&2
    exit 0
  fi
  echo "smartx-agent: no installer under $iso and no warmed agent in $dst" >&2
  exit 1
fi

if [ -n "$installer" ]; then
  tmp="$(mktemp -d "$dst/.warmup.XXXXXX")"
  trap 'rm -rf "$tmp"' EXIT
  # SMTX_VM_TOOLS_INSTALL.sh is a makeself archive. --noexec extracts the
  # Linux payload without running the vendor installer.
  bash "$installer" --noexec --noprogress --target "$tmp" >/dev/null
  src="$tmp"
fi

case "$(uname -m)" in
x86_64)
  ga="qemu-ga"
  ip="ip-manager"
  ;;
aarch64)
  ga="qemu-ga-aarch64"
  ip="ip-manager-aarch64"
  ;;
*)
  echo "smartx-agent: unsupported architecture $(uname -m)" >&2
  exit 1
  ;;
esac

if [ ! -f "$src/$ga" ] || [ ! -f "$src/VERSION" ]; then
  echo "smartx-agent: payload under $src is missing $ga or VERSION" >&2
  exit 1
fi

cp -a "$src/$ga" "$dst/qemu-ga"
cp -a "$src/VERSION" "$dst/VERSION"
for f in ip-manager ip-manager-aarch64 fsfreeze-hook fsfreeze-hook.d COPYING; do
  if [ -e "$src/$f" ]; then
    cp -a "$src/$f" "$dst/$f"
  fi
done
if [ "$ip" != "ip-manager" ] && [ -f "$src/$ip" ]; then
  cp -a "$src/$ip" "$dst/ip-manager"
fi

chmod 0755 "$dst/qemu-ga" "$dst/fsfreeze-hook"
if [ -f "$dst/ip-manager" ]; then
  chmod 0755 "$dst/ip-manager"
fi

printf '%s\n' "$source_id" >"$dst/.source-id"
