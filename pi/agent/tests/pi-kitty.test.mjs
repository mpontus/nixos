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
  const commands = new Map();
  const calls = [];
  const notifications = [];
  const sandbox = {
    process: { env: { KITTY_WINDOW_ID: "13" }, cwd: () => "/project" },
    basename: () => "project", join: (...parts) => parts.join("/"), homedir: () => "/home/test",
    readFileSync: () => "{}", writeFileSync: () => assert.fail("Unexpected bell"),
    spawnSync: (...args) => { calls.push(args); return { status: 0 }; },
    SessionManager: {
      open: (file) => {
        assert.equal(file, "/sessions/original.jsonl");
        return {
          createBranchedSession: (leafId) => {
            assert.equal(leafId, "current-leaf");
            return "/sessions/clone.jsonl";
          },
        };
      },
    },
    pi: { on: (name, fn) => handlers.set(name, fn), registerCommand: (name, command) => commands.set(name, command) },
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

  calls.length = 0;
  await handlers.get("agent_start")({});
  calls.length = 0;
  await commands.get("window-clone").handler("", {
    cwd: "/project",
    waitForIdle: () => assert.fail("Cloning must not wait for the active response or tool"),
    sessionManager: {
      getSessionFile: () => "/sessions/original.jsonl",
      getLeafId: () => "current-leaf",
      createBranchedSession: () => assert.fail("Cloning must not mutate the live session"),
    },
    ui: { notify: (...args) => notifications.push(args) },
  });
  if (mode !== "tui") {
    assert.equal(calls.length, 0, `${mode} must not launch a Kitty tab`);
    assert.equal(notifications[0][1], "error");
  } else {
    assert.equal(notifications.length, 0);
    assert.equal(calls.length, 2);
    assert.deepEqual(Array.from(calls[1][1]), [
      "@", "launch", "--match", "window_id:13", "--type=tab",
      "--cwd=/project", "--tab-title=pi-clone", "pi", "--session", "/sessions/clone.jsonl",
    ]);
  }
}
console.log("PASS: headless sessions skip Kitty; calls have a hard timeout; busy cloning never waits or mutates the live session");
