/**
 * subagent: run delegated tasks as interactive pi sessions in background Rex tabs.
 *
 * Parent side: the `subagent` tool opens a tab labelled `🤖 <role> · <name>` running pi, waits for
 *   the child to finish its first run, and returns its final message. Steer by typing in the tab;
 *   cancel with Esc/ctrl+c or by closing the tab. Status icons come from Rex itself.
 * Child side (PI_SUBAGENT_RESULT set): this same extension writes the final message to that file
 *   once a run settles. An aborted run writes nothing, so you can interrupt, steer, and continue.
 */
import { execFile } from "node:child_process";
import { mkdtemp, readFile, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { promisify } from "node:util";
import type { ThinkingLevel } from "@earendil-works/pi-agent-core";
import { StringEnum } from "@earendil-works/pi-ai";
import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";
import { Type } from "typebox";

const run = promisify(execFile);
const THINKING: ThinkingLevel[] = ["off", "minimal", "low", "medium", "high", "xhigh", "max"];
/** Rex's sidebar shows about 22 characters; lead with what identifies the agent. */
const LABEL_MAX = 28;
const MARKER = "🤖";

export const tabLabel = (role: string, name: string): string => {
  const label = `${MARKER} ${role} · ${name}`.replace(/\s+/g, " ");
  return label.length > LABEL_MAX ? `${label.slice(0, LABEL_MAX - 1)}…` : label;
};

const Params = Type.Object({
  role: Type.String({ description: "One-word role shown first in the tab label, e.g. scout, reviewer, worker." }),
  name: Type.String({ description: "Description of the task in at most four words, e.g. 'map auth flow'." }),
  task: Type.String({ description: "Complete, self-contained instructions. The subagent sees nothing of this conversation." }),
  model: Type.Optional(Type.String({ description: 'Model as "provider/id" or bare id. Defaults to the current model.' })),
  thinking: Type.Optional(StringEnum(THINKING, { description: "Thinking level. Defaults to the current level." })),
});

/** Resolve "provider/id" or bare id against models with working credentials. */
function resolveModel(ctx: ExtensionContext, spec: string | undefined): string {
  if (!spec) {
    if (!ctx.model) throw new Error("No current model; pass `model`.");
    return `${ctx.model.provider}/${ctx.model.id}`;
  }
  const available = ctx.modelRegistry.getAvailable();
  const hit = available.find((m) => `${m.provider}/${m.id}` === spec) ?? available.find((m) => m.id === spec);
  if (!hit) throw new Error(`Unknown model "${spec}". Available: ${available.map((m) => `${m.provider}/${m.id}`).join(", ")}`);
  return `${hit.provider}/${hit.id}`;
}

const sleep = (ms: number) => new Promise((r) => setTimeout(r, ms));
const rex = (...args: string[]) => run("rex", args);

function registerChild(pi: ExtensionAPI, resultFile: string) {
  let last: { text: string; stopReason?: string } | undefined;
  pi.on("message_end", (e) => {
    const m = e.message as { role?: string; content?: unknown; stopReason?: string };
    if (m.role !== "assistant" || !Array.isArray(m.content)) return;
    const text = m.content.filter((c: any) => c.type === "text").map((c: any) => c.text).join("\n");
    last = { text, stopReason: m.stopReason };
  });
  pi.on("agent_settled", async () => {
    // Only a finished turn counts: closing the tab settles mid-tool-call (toolUse) or aborted.
    if (!last || !["stop", "length", "error"].includes(last.stopReason ?? "")) return;
    await writeFile(resultFile, JSON.stringify({ ok: last.stopReason !== "error", text: last.text }));
  });
}

function registerParent(pi: ExtensionAPI) {
  pi.registerTool({
    name: "subagent",
    label: "Subagent",
    description:
      "Delegate a self-contained task to an isolated subagent running pi in its own Rex tab, and return its final answer. " +
      "The user can watch it, steer it by typing in its tab, or cancel it by closing the tab. " +
      "Choose `model` and `thinking` per task: cheaper/faster for search and summaries, stronger for hard reasoning. " +
      "Issue several calls in one message to run agents in parallel.",
    promptSnippet: "Delegate a task to a subagent in a Rex tab with a chosen model and thinking level",
    parameters: Params,
    executionMode: "parallel",
    async execute(_id, params, signal, onUpdate, ctx) {
      const session = process.env.REX_SESSION;
      if (!session) throw new Error("subagent needs Rex: REX_SESSION is not set.");
      const model = resolveModel(ctx, params.model);
      const thinking = params.thinking ?? ctx.thinkingLevel ?? "medium";

      const dir = await mkdtemp(join(tmpdir(), "pi-subagent-"));
      const resultFile = join(dir, "result.json");
      const label = tabLabel(params.role, params.name);
      const prompt = `You are a ${params.role} subagent working for another agent. Your final message is returned to it verbatim, so end with a concise, complete answer.`;
      const created = await rex(
        "window", "new", "-s", session, label, "-c", ctx.cwd, "--focus=false", "--json", "--",
        "env", `PI_SUBAGENT_RESULT=${resultFile}`,
        "pi", "--model", model, "--thinking", thinking, "--append-system-prompt", prompt, params.task,
      );
      const windowId: string = JSON.parse(created.stdout).window_id;
      onUpdate?.({ content: [{ type: "text", text: `Started ${label}` }], details: undefined });

      const closeTab = () => rex("window", "close", "-s", session, windowId).catch(() => {});
      const tabExists = async () => {
        try {
          const { stdout } = await rex("window", "ls", "-s", session, "--json");
          return (JSON.parse(stdout).windows as { window_id: string }[]).some((w) => w.window_id === windowId);
        } catch {
          return true; // transient CLI failure: keep waiting
        }
      };

      try {
        for (let tick = 0; ; tick++) {
          if (signal?.aborted) {
            await closeTab();
            return { content: [{ type: "text", text: "Subagent cancelled by the parent." }], details: undefined };
          }
          const raw = await readFile(resultFile, "utf8").catch(() => undefined);
          if (raw) {
            const r = JSON.parse(raw) as { ok: boolean; text: string };
            if (!r.ok) throw new Error(r.text || "Subagent failed.");
            return { content: [{ type: "text", text: r.text || "(subagent produced no text)" }], details: undefined };
          }
          if (tick % 4 === 3 && !(await tabExists())) {
            return {
              content: [{ type: "text", text: `Subagent tab "${label}" was closed before it finished.` }],
              details: undefined,
            };
          }
          await sleep(500);
        }
      } finally {
        await rm(dir, { recursive: true, force: true });
      }
    },
  });
}

export default function (pi: ExtensionAPI) {
  const resultFile = process.env.PI_SUBAGENT_RESULT;
  if (resultFile) registerChild(pi, resultFile);
  else registerParent(pi);
}
