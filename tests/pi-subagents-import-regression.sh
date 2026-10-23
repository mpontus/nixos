#!/usr/bin/env bash
# Check native runner imports against a built Pi package, without an API call.
# Usage: bash tests/pi-subagents-import-regression.sh /nix/store/...-pi-coding-agent-VERSION
set -euo pipefail
pi_root=$(realpath "${1:?Pass the built Pi package directory}")
subagents=${2:-"$HOME/.pi/agent/npm/node_modules/pi-subagents"}
export PI_ASYNC_NATIVE_RUNNER=1
export JITI_ALIAS
JITI_ALIAS=$(node -e 'console.log(JSON.stringify({
  "@earendil-works/pi-ai": process.argv[1] + "/lib/node_modules/pi-monorepo/node_modules/@earendil-works/pi-ai/dist/index.js"
}))' "$pi_root")
node --import "$subagents/runner-peer-preload.mjs" --input-type=module - "$subagents" <<'JS'
import { pathToFileURL } from 'node:url';
await import(pathToFileURL(process.argv[2] + '/src/extension/declaration-pinning.js'));
console.log('PASS: native runner declaration imports resolve against host Pi');
JS
