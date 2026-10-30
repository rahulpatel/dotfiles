/** Runs in the coordinating pi: spawns subagents into detached Rex blocks and tracks them. */
import { execFile } from "node:child_process";
import { mkdtemp, rm } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { promisify } from "node:util";
import type { ThinkingLevel } from "@earendil-works/pi-agent-core";
import { StringEnum } from "@earendil-works/pi-ai";
import type { AgentToolResult, ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";
import { Text } from "@earendil-works/pi-tui";
import { Type } from "typebox";
import { ENV_DIR, read, sleep, write } from "./protocol.ts";

const run = promisify(execFile);
const rex = (...args: string[]) => run("rex", args);
const THINKING: ThinkingLevel[] = ["off", "minimal", "low", "medium", "high", "xhigh", "max"];
const MARKER = "🤖";

type State = "running" | "asking" | "done" | "failed" | "closed";
interface Agent {
  id: string;
  label: string;
  dir: string;
  block: string;
  state: State;
  attached: boolean;
  surfacedQuestion: number;
}
interface Details { id: string; label: string; state: State; lines: string[] }

const agents = new Map<string, Agent>();
let counter = 0;
const live = (a: Agent) => a.state === "running" || a.state === "asking";

const session = () => {
  const s = process.env.REX_SESSION;
  if (!s) throw new Error("subagent needs Rex: REX_SESSION is not set.");
  return s;
};
const api = (method: string, args: object) => rex("api", "call", "-s", session(), method, JSON.stringify(args));

function updateFooter(ctx: ExtensionContext) {
  if (ctx.mode !== "tui") return;
  const n = [...agents.values()].filter(live).length;
  const asking = [...agents.values()].filter((a) => a.state === "asking").length;
  ctx.ui.setStatus("subagents", n ? `${MARKER} ${n} running${asking ? ` · ${asking} asking` : ""}` : undefined);
}

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

const blockExists = async (id: string) => {
  try {
    const { stdout } = await rex("block", "ls", "-s", session(), "--json");
    return (JSON.parse(stdout).blocks as { block_id: string }[]).some((b) => b.block_id === id);
  } catch {
    return true; // transient CLI failure: keep waiting
  }
};

const text = (t: string, details?: Details): AgentToolResult<Details | undefined> => ({
  content: [{ type: "text", text: t }],
  details,
});

/** Wait until the agent finishes, asks a question, or goes away. */
async function waitForOutcome(
  agent: Agent,
  ctx: ExtensionContext,
  signal: AbortSignal | undefined,
  onUpdate: ((r: AgentToolResult<Details | undefined>) => void) | undefined,
): Promise<AgentToolResult<Details | undefined>> {
  const snapshot = async (): Promise<Details> => ({
    id: agent.id,
    label: agent.label,
    state: agent.state,
    lines: (await read(agent.dir, "activity"))?.lines ?? [],
  });
  let shown = "";
  for (let tick = 0; ; tick++) {
    if (signal?.aborted) {
      agent.state = "closed";
      await rex("block", "close", "-s", session(), agent.block).catch(() => {});
      updateFooter(ctx);
      return text(`Subagent ${agent.id} cancelled by the parent.`);
    }
    const result = await read(agent.dir, "result");
    if (result) {
      agent.state = result.ok ? "done" : "failed";
      updateFooter(ctx);
      if (!result.ok) throw new Error(result.text || `Subagent ${agent.id} failed.`);
      return text(result.text || "(subagent produced no text)", await snapshot());
    }
    const q = await read(agent.dir, "question");
    if (q && q.n > agent.surfacedQuestion) {
      agent.surfacedQuestion = q.n;
      agent.state = "asking";
      updateFooter(ctx);
      return text(
        `Subagent ${agent.id} is blocked and asks:\n\n${q.text}\n\nAnswer it with subagent_reply(id: "${agent.id}", answer: ...). It waits until you do.`,
        await snapshot(),
      );
    }
    if (agent.state === "asking") {
      agent.state = "running";
      updateFooter(ctx);
    }
    const snap = await snapshot();
    const key = snap.lines.join("\n");
    if (key !== shown) {
      shown = key;
      onUpdate?.(text(snap.lines.at(-1) ?? "working…", snap));
    }
    if (tick % 4 === 3 && !(await blockExists(agent.block))) {
      agent.state = "closed";
      updateFooter(ctx);
      return text(`Subagent ${agent.id} was closed before it finished.`);
    }
    await sleep(500);
  }
}

const Spawn = Type.Object({
  role: Type.String({ description: "One-word role shown first in the label, e.g. scout, reviewer, worker." }),
  name: Type.String({ description: "Description of the task in at most four words, e.g. 'map auth flow'." }),
  task: Type.String({ description: "Complete, self-contained instructions. The subagent sees nothing of this conversation." }),
  model: Type.Optional(Type.String({ description: 'Model as "provider/id" or bare id. Defaults to the current model.' })),
  thinking: Type.Optional(StringEnum(THINKING, { description: "Thinking level. Defaults to the current level." })),
});

const Reply = Type.Object({
  id: Type.String({ description: "Subagent id from the question, e.g. scout-1." }),
  answer: Type.String({ description: "Your answer to the subagent's question." }),
});

export function registerParent(pi: ExtensionAPI): void {
  pi.registerTool({
    name: "subagent",
    label: "Subagent",
    description:
      "Delegate a self-contained task to an isolated subagent (its own pi session, hidden until the user attaches it) and return its final answer. " +
      "Choose `model` and `thinking` per task: cheaper/faster for search and summaries, stronger for hard reasoning. " +
      "Issue several calls in one message to run agents in parallel. " +
      "If the subagent is stuck it asks you a question instead of a result: answer with subagent_reply.",
    promptSnippet: "Delegate a task to a subagent with a chosen model and thinking level",
    parameters: Spawn,
    executionMode: "parallel",
    async execute(_id, params, signal, onUpdate, ctx) {
      const model = resolveModel(ctx, params.model);
      const thinking = params.thinking ?? ctx.thinkingLevel ?? "medium";
      const id = `${params.role.toLowerCase().replace(/\W+/g, "-")}-${++counter}`;
      const dir = await mkdtemp(join(tmpdir(), `pi-subagent-${id}-`));
      const label = `${MARKER} ${params.role} · ${params.name}`;
      const systemPrompt =
        `You are a ${params.role} subagent working for a coordinating agent. Your final message is returned to it verbatim, so end with a concise, complete answer. ` +
        "If you are stuck or the task is ambiguous, call ask_coordinator instead of guessing.";

      const created = JSON.parse(
        (
          await rex(
            "window", "new", "-s", session(), label, "-c", ctx.cwd, "--focus=false", "--keep-open", "--json", "--",
            "env", `${ENV_DIR}=${dir}`,
            "pi", "--model", model, "--thinking", thinking, "--append-system-prompt", systemPrompt, params.task,
          )
        ).stdout,
      ) as { block_ids: string[] };
      const block = created.block_ids[0]!;
      await api("session.detach_block", { block_id: block }); // hide: out of the sidebar, still running

      const agent: Agent = { id, label, dir, block, state: "running", attached: false, surfacedQuestion: 0 };
      agents.set(id, agent);
      updateFooter(ctx);
      return waitForOutcome(agent, ctx, signal, onUpdate);
    },
    renderCall(args, theme) {
      return new Text(`${theme.bold(`${MARKER} ${args.role}`)} ${theme.fg("dim", `· ${args.name}`)}${args.model ? theme.fg("dim", `  ${args.model}`) : ""}`, 0, 0);
    },
    renderResult(result, { expanded, isPartial }, theme) {
      const d = result.details as Details | undefined;
      const body = result.content.map((c) => (c.type === "text" ? c.text : "")).join("");
      if (isPartial && d) {
        const shown = d.lines.slice(expanded ? -12 : -3).map((l) => theme.fg("muted", `  ${l}`));
        return new Text([theme.fg("accent", `● ${d.id} working`), ...shown].join("\n"), 0, 0);
      }
      const head = d ? theme.fg(d.state === "asking" ? "warning" : "success", `${d.state === "asking" ? "❓" : "✓"} ${d.id}`) : "";
      const lines = body.split("\n");
      const shown = expanded ? lines : lines.slice(0, 6);
      const more = lines.length > shown.length ? theme.fg("dim", `\n… ${lines.length - shown.length} more lines (ctrl+o)`) : "";
      return new Text(`${head}\n${shown.join("\n")}${more}`, 0, 0);
    },
  });

  pi.registerTool({
    name: "subagent_reply",
    label: "Subagent reply",
    description: "Answer a question a subagent asked, then wait for it to finish or ask again.",
    promptSnippet: "Answer a blocked subagent's question",
    parameters: Reply,
    executionMode: "parallel",
    async execute(_id, params, signal, onUpdate, ctx) {
      const agent = agents.get(params.id);
      if (!agent) throw new Error(`No subagent "${params.id}". Known: ${[...agents.keys()].join(", ") || "none"}`);
      if (agent.state !== "asking") throw new Error(`Subagent ${agent.id} is ${agent.state}, not waiting for an answer.`);
      await write(agent.dir, "answer", { n: agent.surfacedQuestion, text: params.answer });
      agent.state = "running";
      updateFooter(ctx);
      return waitForOutcome(agent, ctx, signal, onUpdate);
    },
  });

  const names = () => [...agents.keys()];
  const pick = async (ctx: ExtensionContext, arg: string, want: (a: Agent) => boolean, verb: string) => {
    const candidates = [...agents.values()].filter(want);
    if (arg) return candidates.find((a) => a.id === arg) ?? (ctx.ui.notify(`No subagent "${arg}" to ${verb}`, "warning"), undefined);
    if (candidates.length <= 1) return candidates[0] ?? (ctx.ui.notify(`No subagent to ${verb}`, "info"), undefined);
    const choice = await ctx.ui.select(`${verb} which subagent?`, candidates.map((a) => `${a.id}  ${a.label}`));
    return candidates.find((a) => choice?.startsWith(`${a.id} `));
  };
  const complete = (prefix: string) => names().filter((n) => n.startsWith(prefix)).map((n) => ({ value: n, label: n }));

  pi.registerCommand("attach", {
    description: "Show a subagent in a split beside this pane",
    getArgumentCompletions: complete,
    handler: async (arg, ctx) => {
      const agent = await pick(ctx, arg.trim(), (a) => !a.attached && a.state !== "closed", "attach");
      if (!agent) return;
      const anchor = process.env.REX_BLOCK;
      if (!anchor) return ctx.ui.notify("REX_BLOCK is not set; cannot place the split.", "error");
      await api("session.move_block", { block_id: agent.block, anchor_block_id: anchor, direction: "horizontal", side: "after", ratio: 0.5 });
      await rex("focus", "-s", session(), agent.block).catch(() => {});
      agent.attached = true;
    },
  });

  pi.registerCommand("detach", {
    description: "Hide an attached subagent again (it keeps running)",
    getArgumentCompletions: complete,
    handler: async (arg, ctx) => {
      const agent = await pick(ctx, arg.trim(), (a) => a.attached, "detach");
      if (!agent) return;
      await api("session.detach_block", { block_id: agent.block });
      agent.attached = false;
      await rex("focus", "-s", session(), process.env.REX_BLOCK ?? "").catch(() => {});
    },
  });

  pi.on("session_shutdown", async () => {
    await Promise.all(
      [...agents.values()].map(async (a) => {
        await rex("block", "close", "-s", session(), a.block).catch(() => {});
        await rm(a.dir, { recursive: true, force: true });
      }),
    );
    agents.clear();
  });
}
