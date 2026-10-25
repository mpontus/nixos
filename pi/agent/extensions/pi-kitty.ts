import { spawnSync } from "node:child_process";
import { readFileSync, writeFileSync } from "node:fs";
import { basename, join } from "node:path";
import { homedir } from "node:os";
import { SessionManager, type ExtensionAPI } from "@earendil-works/pi-coding-agent";

const kittyWindowId = process.env.KITTY_WINDOW_ID;
const project = basename(process.cwd());
const activeTools = new Map<string, string>();
let running = false;
let terminalEnabled = false;
const kittyTimeout = { timeout: 1000, killSignal: "SIGKILL" as const };
let currentModel: string | undefined;

function loadAttentionPatterns(): { patterns: RegExp[]; invalid: string[] } {
  let values: unknown = ["^ask_user$"];
  try {
    const settings = JSON.parse(readFileSync(join(homedir(), ".pi", "agent", "settings.json"), "utf8"));
    values = settings.piKitty?.attentionToolPatterns ?? values;
  } catch {
    // Pi reports malformed settings separately; retain safe defaults here.
  }

  if (!Array.isArray(values)) values = ["^ask_user$"];

  const patterns: RegExp[] = [];
  const invalid: string[] = [];
  for (const value of values) {
    if (typeof value !== "string") {
      invalid.push(String(value));
      continue;
    }
    try {
      patterns.push(new RegExp(value));
    } catch {
      invalid.push(value);
    }
  }
  return { patterns, invalid };
}

const attention = loadAttentionPatterns();

function setKittyTitle(title: string): void {
  if (!terminalEnabled || !kittyWindowId) return;
  // Terminal cosmetics must not indefinitely block tool execution.
  spawnSync(
    "kitten",
    ["@", "set-window-title", "--temporary", "--match", `id:${kittyWindowId}`, title],
    { stdio: "ignore", ...kittyTimeout },
  );
}

function hasKittyRemoteControl(): boolean {
  if (!kittyWindowId) return false;
  return spawnSync(
    "kitten",
    ["@", "ls", "--match", `id:${kittyWindowId}`],
    { stdio: "ignore", ...kittyTimeout },
  ).status === 0;
}

function idleTitle(): string {
  return `π ${project}${currentModel ? ` · ${currentModel}` : ""}`;
}

function updateTitle(): void {
  const tool = Array.from(activeTools.values()).at(-1);
  setKittyTitle(running ? `… π ${project} · ${tool ?? currentModel ?? "working"}` : idleTitle());
}

function ringBell(): void {
  if (!terminalEnabled) return;
  try {
    writeFileSync("/dev/tty", "\x07");
  } catch {
    // No controlling terminal in print/subagent contexts.
  }
}

export default function piKitty(pi: ExtensionAPI) {
  pi.on("session_start", async (_event, ctx) => {
    // Subagents inherit KITTY_WINDOW_ID but do not own the parent's terminal.
    terminalEnabled = ctx.mode === "tui";
    currentModel = ctx.model?.id;
    if (kittyWindowId && attention.invalid.length > 0) {
      ctx.ui.notify(
        `pi-kitty ignored invalid attention regex: ${attention.invalid.join(", ")}`,
        "warning",
      );
    }
    updateTitle();
  });

  pi.on("model_select", async (event) => {
    currentModel = event.model.id;
    updateTitle();
  });

  pi.on("agent_start", async () => {
    running = true;
    updateTitle();
  });

  pi.on("tool_execution_start", async (event) => {
    activeTools.set(event.toolCallId, event.toolName);
    updateTitle();
    if (kittyWindowId && attention.patterns.some((pattern) => pattern.test(event.toolName))) {
      ringBell();
    }
  });

  pi.on("tool_execution_end", async (event) => {
    activeTools.delete(event.toolCallId);
    updateTitle();
  });

  pi.on("agent_settled", async () => {
    running = false;
    activeTools.clear();
    updateTitle();
  });

  pi.on("session_shutdown", async () => {
    setKittyTitle(`π ${project}`);
  });

  pi.registerCommand("window-clone", {
    description: "Clone the current conversation into a new Kitty tab without waiting for active work",
    handler: async (_args, ctx) => {
      if (!terminalEnabled || !kittyWindowId) {
        ctx.ui.notify("/window-clone requires Pi to run inside Kitty.", "error");
        return;
      }

      if (!hasKittyRemoteControl()) {
        ctx.ui.notify("Kitty remote control is unavailable.", "error");
        return;
      }

      const sessionFile = ctx.sessionManager.getSessionFile();
      if (!sessionFile) {
        ctx.ui.notify("Current session is ephemeral; cannot clone it.", "error");
        return;
      }

      const leafId = ctx.sessionManager.getLeafId();
      if (!leafId) {
        ctx.ui.notify("Current session has no active branch to clone.", "error");
        return;
      }

      // Branch a separate manager so active work keeps writing to the original session.
      const clonedSession = SessionManager.open(sessionFile).createBranchedSession(leafId);
      if (!clonedSession) {
        ctx.ui.notify("Failed to create cloned session.", "error");
        return;
      }

      const result = spawnSync(
        "kitten",
        [
          "@",
          "launch",
          "--match",
          `window_id:${kittyWindowId}`,
          "--type=tab",
          `--cwd=${ctx.cwd}`,
          "--tab-title=pi-clone",
          "pi",
          "--session",
          clonedSession,
        ],
        { encoding: "utf8", ...kittyTimeout },
      );

      if (result.error || result.status !== 0) {
        const error = result.error?.message ?? result.stderr.trim() ?? "unknown Kitty error";
        ctx.ui.notify(`Failed to open Kitty tab: ${error}`, "error");
      }
    },
  });
}
