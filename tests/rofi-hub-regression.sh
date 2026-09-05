#!/usr/bin/env bash
set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
export HOME="$tmp/home" XDG_RUNTIME_DIR="$tmp/run"
mkdir -p "$HOME/.config/rofi" "$XDG_RUNTIME_DIR"
printf 'Nix|https://example.test/nix\n' > "$HOME/.config/rofi/bookmarks"
printf 'Shrug|test\n' > "$HOME/.config/rofi/snippets"

get_script() {
  nix eval --raw "$root#nixosConfigurations.nixos.config.home-manager.users.mpontus.home.file.\"$1\".text"
}
get_script .local/bin/rofi-hub > "$tmp/hub"
get_script .local/bin/rofi-clipboard > "$tmp/clipboard"
chmod +x "$tmp/hub" "$tmp/clipboard"

cat > "$tmp/rofi" <<'EOF'
#!/bin/sh
input=$(cat)
case " $* " in
  *' -p Web '*) printf '%s' "$input" | grep -q 'Nix|https://example.test/nix'; printf 'Nix|https://example.test/nix\n' ;;
  *' -p Displays '*) printf 'Mirror to projector\n' ;;
  *' -p Clipboard '*) [ "${CANCEL:-0}" = 1 ] && exit 1; printf '0\n' ;;
  *) exit 1 ;;
esac
EOF
cat > "$tmp/open" <<EOF
#!/bin/sh
printf '%s\n' "\$*" >> '$tmp/open.log'
EOF
cat > "$tmp/xrandr" <<EOF
#!/bin/sh
printf 'eDP-1 connected primary 1920x1080+0+0\n'
[ \$# -eq 0 ] || printf '%s\n' "\$*" >> '$tmp/xrandr-actions.log'
EOF
cat > "$tmp/xclip" <<EOF
#!/bin/sh
printf '%s\n' "\$*" >> '$tmp/xclip.log'
EOF
chmod +x "$tmp/rofi" "$tmp/open" "$tmp/xrandr" "$tmp/xclip"

ROFI_HUB_CHECK=1 "$tmp/hub"
ROFI_HUB_ROFI="$tmp/rofi" ROFI_HUB_XDG_OPEN="$tmp/open" "$tmp/hub" 'Web + bookmarks'
grep -qx 'https://example.test/nix' "$tmp/open.log"
ROFI_HUB_ROFI="$tmp/rofi" ROFI_HUB_XRANDR="$tmp/xrandr" "$tmp/hub" Displays
[ ! -e "$tmp/xrandr-actions.log" ]

mkdir "$XDG_RUNTIME_DIR/rofi-clipboard"
printf 'safe clipboard value' > "$XDG_RUNTIME_DIR/rofi-clipboard/item.txt"
ROFI_CLIPBOARD_ROFI="$tmp/rofi" ROFI_CLIPBOARD_XCLIP="$tmp/xclip" "$tmp/clipboard"
grep -q -- '-i .*/rofi-clipboard/item.txt' "$tmp/xclip.log"
rm "$tmp/xclip.log"
CANCEL=1 ROFI_CLIPBOARD_ROFI="$tmp/rofi" ROFI_CLIPBOARD_XCLIP="$tmp/xclip" "$tmp/clipboard"
[ ! -e "$tmp/xclip.log" ]

echo 'rofi hub regression: ok'
