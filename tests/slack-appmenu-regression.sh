#!/usr/bin/env bash
# Run inside the graphical session (or its SSH user session) with Slack open.
# Requires busctl and jq. Checks the real exported menu, not just registration.
set -euo pipefail
command -v busctl jq >/dev/null

menus=$(busctl --user --json=short call \
  com.canonical.AppMenu.Registrar /com/canonical/AppMenu/Registrar \
  com.canonical.AppMenu.Registrar GetMenus)

while IFS=$'\t' read -r window service path; do
  pid=$(busctl --user --json=short call org.freedesktop.DBus \
    /org/freedesktop/DBus org.freedesktop.DBus GetConnectionUnixProcessID \
    s "$service" | jq -r '.data[0]')
  [[ $(readlink "/proc/$pid/exe") == */lib/slack/slack ]] || continue

  layout=$(busctl --user --json=short call "$service" "$path" \
    com.canonical.dbusmenu GetLayout iias 0 1 0)
  jq -e '
    [.data[1][2][].data[1].label.data | gsub("_"; "")] as $labels
    | (["File", "Edit", "View", "Help"] - $labels | length) == 0
  ' <<<"$layout" >/dev/null
  grep -q 'libdbusmenu-glib\.so' "/proc/$pid/maps"
  echo "PASS: Slack window $window exports File/Edit/View/Help with libdbusmenu loaded."
  exit 0
done < <(jq -r '.data[0][] | @tsv' <<<"$menus")

echo 'FAIL: No registered Slack menu. Open Slack in the graphical session.' >&2
exit 1
