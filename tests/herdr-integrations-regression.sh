#!/usr/bin/env bash
# Exercise the evaluated Home Manager activation without touching the real home.
# Usage: bash tests/herdr-integrations-regression.sh ACTIVATION_SCRIPT HOME_MANAGER_SOURCE
set -euo pipefail
activation=$(realpath "${1:?Pass the evaluated herdrIntegrations activation script}")
hm_source=$(realpath "${2:?Pass the pinned Home Manager source directory}")
work=$(mktemp -d)
trap 'rm -rf -- "$work"' EXIT
export HOME="$work/home"
# Activation must target this user's default configs, not inherited agent profiles.
export CODEX_HOME="$work/other-codex" PI_CODING_AGENT_DIR="$work/other-pi"
source "$hm_source/lib/bash/home-manager.sh"

export DRY_RUN=1
source "$activation"
test ! -e "$HOME"
unset DRY_RUN

mkdir -p "$HOME/.codex" "$HOME/.pi" "$HOME/pi-config/agent/extensions"
ln -s ../pi-config/agent "$HOME/.pi/agent"
printf 'model = "keep-me"\n[features]\nshell_snapshot = false\n' > "$HOME/.codex/config.toml"
printf '%s\n' '{"hooks":{"SessionStart":[{"hooks":[{"type":"command","command":"echo keep-existing-hook"}]}]}}' > "$HOME/.codex/hooks.json"
chmod 600 "$HOME/.codex/config.toml" "$HOME/.codex/hooks.json"
printf '// keep-existing-extension\n' > "$HOME/.pi/agent/extensions/existing.ts"
source "$activation"

python3 - <<'PY'
import json
import os
from pathlib import Path
import tomllib

home = Path.home()
config = tomllib.loads((home / ".codex/config.toml").read_text())
assert config["model"] == "keep-me"
assert config["features"]["shell_snapshot"] is False
assert config["features"]["hooks"] is True
assert (home / ".codex/config.toml").stat().st_mode & 0o777 == 0o600
assert (home / ".codex/hooks.json").stat().st_mode & 0o777 == 0o600
hooks = json.loads((home / ".codex/hooks.json").read_text())
commands = [hook["command"] for entry in hooks["hooks"]["SessionStart"] for hook in entry["hooks"]]
assert commands.count("echo keep-existing-hook") == 1
assert sum("herdr-agent-state.sh" in command for command in commands) == 1
assert any(str(home / ".codex/herdr-agent-state.sh") in command for command in commands)
assert (home / ".pi/agent").is_symlink()
assert (home / ".pi/agent/extensions/existing.ts").read_text() == "// keep-existing-extension\n"
assert "HERDR_INTEGRATION_ID=pi" in (home / ".pi/agent/extensions/herdr-agent-state.ts").read_text()
assert "HERDR_INTEGRATION_ID=codex" in (home / ".codex/herdr-agent-state.sh").read_text()
assert not Path(os.environ["CODEX_HOME"]).exists()
assert not Path(os.environ["PI_CODING_AGENT_DIR"]).exists()
PY

files=("$HOME/.codex/config.toml" "$HOME/.codex/hooks.json" "$HOME/.codex/herdr-agent-state.sh" "$HOME/.pi/agent/extensions/herdr-agent-state.ts")
sha256sum "${files[@]}" > "$work/before"
source "$activation"
sha256sum "${files[@]}" > "$work/after"
cmp "$work/before" "$work/after"

# A fresh home must also work, without either agent having been launched before.
export HOME="$work/fresh-home"
source "$activation"
test -f "$HOME/.codex/hooks.json"
test -f "$HOME/.pi/agent/extensions/herdr-agent-state.ts"
python3 - <<'PY'
from pathlib import Path
import tomllib
home = Path.home()
assert tomllib.loads((home / ".codex/config.toml").read_text())["features"]["hooks"] is True
assert (home / ".codex").stat().st_mode & 0o777 == 0o700
assert (home / ".pi/agent").stat().st_mode & 0o777 == 0o700
PY
printf 'PASS: fresh install, dry run, repeat activation, permissions, existing hooks/settings, and symlinked Pi config\n'
