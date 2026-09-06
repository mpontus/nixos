#!/usr/bin/env bash
set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
export HOME="$tmp/home" XDG_RUNTIME_DIR="$tmp/run"
mkdir -p "$HOME/.config/rofi" "$HOME/.ssh" "$HOME/projects/demo" "$XDG_RUNTIME_DIR"
printf 'Nix|https://example.test/nix\nHostile $(touch /tmp/rofi-pwned)|https://example.test/safe\n' > "$HOME/.config/rofi/bookmarks"
printf 'Shrug|test\n' > "$HOME/.config/rofi/snippets"
printf 'Host demo\nHost * wildcard\n' > "$HOME/.ssh/config"

get_script() {
  nix eval --raw "$root#nixosConfigurations.nixos.config.home-manager.users.mpontus.home.file.\"$1\".text"
}
get_script .local/bin/rofi-hub > "$tmp/hub"
get_script .local/bin/rofi-actions > "$tmp/actions"
get_script .local/bin/rofi-clipboard > "$tmp/clipboard"
chmod +x "$tmp/hub" "$tmp/actions" "$tmp/clipboard"

cat > "$tmp/rofi" <<'EOF'
#!/bin/sh
printf '%s\n' "$*" >> "$MOCK_LOG"
input=$(cat)
case " $* " in
  *' -show combi '*) [ "${CANCEL:-0}" = 1 ] && exit 1; [ "${CALC:-0}" = 1 ] && { printf '2+2'; exit 10; }; exit 0 ;;
  *' -p Displays '*) printf 'Mirror to projector\n' ;;
  *' -p Clipboard '*) [ "${CANCEL:-0}" = 1 ] && exit 1; printf '0\n' ;;
  *) exit 0 ;;
esac
EOF
cat > "$tmp/open" <<'EOF'
#!/bin/sh
printf '%s\n' "$*" >> "$OPEN_LOG"
EOF
cat > "$tmp/hub-action" <<'EOF'
#!/bin/sh
printf '%s\n' "$*" >> "$HUB_LOG"
EOF
cat > "$tmp/xrandr" <<'EOF'
#!/bin/sh
printf 'eDP-1 connected primary 1920x1080+0+0\n'
[ $# -eq 0 ] || printf '%s\n' "$*" >> "$XRANDR_LOG"
EOF
cat > "$tmp/xclip" <<'EOF'
#!/bin/sh
printf '%s\n' "$*" >> "$XCLIP_LOG"
EOF
chmod +x "$tmp"/{rofi,open,hub-action,xrandr,xclip}
export MOCK_LOG="$tmp/rofi.log" OPEN_LOG="$tmp/open.log" HUB_LOG="$tmp/hub.log" XRANDR_LOG="$tmp/xrandr.log" XCLIP_LOG="$tmp/xclip.log"

ROFI_HUB_CHECK=1 "$tmp/hub"
ROFI_RETV=0 "$tmp/actions" > "$tmp/items"
grep -aF 'Nix' "$tmp/items" >/dev/null
grep -aF 'demo' "$tmp/items" >/dev/null
grep -aF 'Shrug' "$tmp/items" >/dev/null
grep -aF 'demo' "$tmp/items" >/dev/null

# Script-mode selection uses metadata ID, never selected display text.
ROFI_RETV=1 ROFI_INFO=bookmark:0 ROFI_HUB_XDG_OPEN="$tmp/open" "$tmp/actions" 'ignored hostile text'
grep -qx 'https://example.test/nix' "$tmp/open.log"
ROFI_RETV=1 ROFI_INFO=bookmark:1 ROFI_HUB_XDG_OPEN="$tmp/open" "$tmp/actions" '$(touch /tmp/rofi-pwned)'
[ ! -e /tmp/rofi-pwned ]
grep -qx 'https://example.test/safe' "$tmp/open.log"
ROFI_RETV=1 ROFI_INFO=action:Lock ROFI_ACTIONS_HUB="$tmp/hub-action" "$tmp/actions"
grep -qx Lock "$tmp/hub.log"

ROFI_HUB_ROFI="$tmp/rofi" "$tmp/hub"
grep -q -- '-combi-modes drun,window,actions' "$tmp/rofi.log"
grep -q -- '-message All destinations' "$tmp/rofi.log"
CANCEL=1 ROFI_HUB_ROFI="$tmp/rofi" "$tmp/hub"
CALC=1 ROFI_HUB_ROFI="$tmp/rofi" "$tmp/hub"
grep -q -- '-show calc .* -no-history .* -message Enter copies result .* -filter 2+2' "$tmp/rofi.log"

ROFI_HUB_ROFI="$tmp/rofi" ROFI_HUB_XRANDR="$tmp/xrandr" "$tmp/hub" Displays
[ ! -e "$tmp/xrandr.log" ]

mkdir "$XDG_RUNTIME_DIR/rofi-clipboard"
printf 'safe clipboard value' > "$XDG_RUNTIME_DIR/rofi-clipboard/item.txt"
ROFI_CLIPBOARD_ROFI="$tmp/rofi" ROFI_CLIPBOARD_XCLIP="$tmp/xclip" "$tmp/clipboard"
grep -q -- '-i .*/rofi-clipboard/item.txt' "$tmp/xclip.log"
rm "$tmp/xclip.log"
CANCEL=1 ROFI_CLIPBOARD_ROFI="$tmp/rofi" ROFI_CLIPBOARD_XCLIP="$tmp/xclip" "$tmp/clipboard"
[ ! -e "$tmp/xclip.log" ]

echo "store preview: $tmp/hub $tmp/actions $tmp/clipboard"
echo 'rofi palette regression: ok'
