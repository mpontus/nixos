#!/usr/bin/env bash
# Run in a disposable graphical VM with no other DomTerm frontend running.
# Usage: bash tests/domterm-session-regression.sh /path/to/domterm /path/to/settings.ini
set -euo pipefail
exe=${1:-domterm}
settings=${2:-$HOME/.config/domterm/settings.ini}
socket="domterm-regression-$$"
pid=
run() { "$exe" --socket-name="$socket" "$@"; }
cleanup() {
  # This PID belongs only to the shell created by this check.
  if [[ -n $pid ]]; then kill -HUP "$pid" 2>/dev/null || true; fi
}
trap cleanup EXIT
wait_ready() {
  for ((i=0; i<30; i++)); do
    state=$(run status)
    if grep -q 'electron:' <<<"$state" && grep -Eq 'Terminal#[0-9]+: pid: [0-9]+' <<<"$state"; then
      return 0
    fi
    sleep 1
  done
  printf 'FAIL: Electron did not attach\n%s\n' "$state" >&2
  return 1
}
run --settings="$settings"
wait_ready
pid=$(sed -nE 's/.*Terminal#[0-9]+: pid: ([0-9]+),.*/\1/p' <<<"$state")
[[ $pid =~ ^[0-9]+$ ]]
run -w 1 detach
for ((i=0; i<30; i++)); do
  state=$(run status)
  if grep -q 'Detached sessions:' <<<"$state" && ! grep -q '^Window ' <<<"$state"; then
    break
  fi
  sleep 1
done
grep -q 'Detached sessions:' <<<"$state"
if grep -q '^Window ' <<<"$state"; then
  echo 'FAIL: detach left a GUI view attached.' >&2
  exit 1
fi
kill -0 "$pid"
run attach 1
wait_ready
grep -q "pid: $pid," <<<"$state"
echo "PASS: Electron detached and reattached to the same live shell ($pid)."
