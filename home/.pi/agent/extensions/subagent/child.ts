/** Runs inside a subagent's pi: reports activity and the final result, and can ask the coordinator. */
import { rm } from "node:fs/promises";
import { join } from "node:path";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { Type } from "typebox";
import { execFile } from "node:child_process";
import { promisify } from "node:util";
import { ENV_PARENT_BLOCK, read, sleep, write } from "./protocol.ts";

const rex = promisify(execFile).bind(null, "rex");

const MAX_LINES = 40;
const oneLine = (v: unknown, n = 100) => {
  const flat = (typeof v === "string" ? v : JSON.stringify(v) ?? "").replace(/\s+/g, " ");
  return flat.length > n ? `${flat.slice(0, n - 1)}…` : flat;
};

export function registerChild(pi: ExtensionAPI, dir: string): void {
  const lines: string[] = [];
  const log = (line: string) => {
    lines.push(line);
    if (lines.length > MAX_LINES) lines.shift();
    // Best effort: the live card is not worth crashing the agent over.
    write(dir, "activity", { lines: [...lines] }).catch(() => {});
  };

  let last: { text: string; stopReason?: string; error?: string } | undefined;
  pi.on("tool_execution_start", (e) => log(`→ ${e.toolName} ${oneLine(e.args)}`));
  pi.on("message_end", (e) => {
    const m = e.message as { role?: string; content?: unknown; stopReason?: string; errorMessage?: string };
    if (m.role !== "assistant" || !Array.isArray(m.content)) return;
    const text = m.content.filter((c: any) => c.type === "text").map((c: any) => c.text).join("\n");
    last = { text, stopReason: m.stopReason, error: m.errorMessage };
    if (text.trim()) log(oneLine(text));
  });
  pi.on("agent_settled", async () => {
    // Only a finished turn counts: closing the tab settles mid-tool-call (toolUse) or aborted.
    if (!last || !["stop", "length", "error"].includes(last.stopReason ?? "")) return;
    const failed = last.stopReason === "error";
    await write(dir, "result", { ok: !failed, text: failed ? last.error || last.text || "Subagent run failed with no error message." : last.text });
  });

  pi.registerCommand("detach", {
    description: "Hide this subagent again (it keeps running in the background)",
    handler: async (_args, ctx) => {
      const { REX_SESSION: session, REX_BLOCK: block } = process.env;
      if (!session || !block) return ctx.ui.notify("Not running in a Rex pane.", "error");
      await rex(["api", "call", "-s", session, "session.detach_block", JSON.stringify({ block_id: block })]);
      const parent = process.env[ENV_PARENT_BLOCK];
      if (parent) await rex(["focus", "-s", session, parent]).catch(() => {});
    },
  });

  let asked = 0;
  pi.registerTool({
    name: "ask_coordinator",
    label: "Ask coordinator",
    description:
      "Ask the coordinating agent a question when you are stuck or need a decision you cannot make yourself. " +
      "Blocks until it answers. Do not guess when the task is ambiguous or blocked; ask.",
    promptSnippet: "Ask the coordinating agent when stuck or blocked",
    parameters: Type.Object({ question: Type.String({ description: "A specific question, with the context needed to answer it." }) }),
    async execute(_id, params, signal) {
      const n = ++asked;
      log(`❓ ${oneLine(params.question)}`);
      await write(dir, "question", { n, text: params.question });
      while (!signal?.aborted) {
        const a = await read(dir, "answer");
        if (a?.n === n) {
          await rm(join(dir, "question.json"), { force: true });
          return { content: [{ type: "text", text: a.text }], details: undefined };
        }
        await sleep(500);
      }
      throw new Error("Cancelled while waiting for the coordinator.");
    },
  });
}
