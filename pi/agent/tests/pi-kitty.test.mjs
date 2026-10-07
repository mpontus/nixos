// Run: node pi/agent/tests/pi-kitty.test.mjs
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { stripTypeScriptTypes } from "node:module";
import vm from "node:vm";

const source = stripTypeScriptTypes(readFileSync(new URL("../extensions/pi-kitty.ts", import.meta.url), "utf8"))
  .replace(/^import .*;$/gm, "")
  .replace("export default function", "function");

for (const mode of ["json", "print", "rpc", "tui"]) {
  const handlers = new Map();
  const calls = [];
  const sandbox = {
    process: { env: { KITTY_WINDOW_ID: "13" }, cwd: () => "/project" },
    basename: () => "project", join: (...parts) => parts.join("/"), homedir: () => "/home/test",
    readFileSync: () => "{}", writeFileSync: () => assert.fail("Unexpected bell"),
    spawnSync: (...args) => { calls.push(args); return { status: 0 }; },
    pi: { on: (name, fn) => handlers.set(name, fn), registerCommand: () => {} },
  };
  vm.runInNewContext(`${source}\npiKitty(pi);`, sandbox);
  await handlers.get("session_start")({}, { mode, model: { id: "test" } });
  await handlers.get("agent_start")({});
  await handlers.get("tool_execution_start")({ toolCallId: "1", toolName: "bash" });
  await handlers.get("tool_execution_end")({ toolCallId: "1" });
  await handlers.get("agent_settled")({});
  await handlers.get("session_shutdown")({});
  if (mode !== "tui") assert.equal(calls.length, 0, `${mode} must not control the parent terminal`);
  else {
    assert.equal(calls.length, 6);
    for (const [, , options] of calls) {
      assert.ok(options.timeout > 0 && options.timeout <= 1000, "Kitty calls need a bounded timeout");
      assert.equal(options.killSignal, "SIGKILL", "Timeout must stop an unresponsive kitten");
    }
  }
}
console.log("PASS: headless sessions skip Kitty; title calls have a hard timeout");
