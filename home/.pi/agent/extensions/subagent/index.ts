/**
 * subagent: run delegated tasks in in-process pi sessions.
 *
 * - `subagent` tool: task + optional model + thinking level. Blocks until the child finishes;
 *   several calls in one assistant message run in parallel.
 * - ↑ on an empty editor (or /agents) opens a panel to browse, steer, and cancel running agents.
 */
import type { ThinkingLevel } from "@earendil-works/pi-agent-core";
import { StringEnum } from "@earendil-works/pi-ai";
import {
  createAgentSession,
  type ExtensionAPI,
  type ExtensionContext,
  SessionManager,
} from "@earendil-works/pi-coding-agent";
import { matchesKey } from "@earendil-works/pi-tui";
import { Type } from "typebox";
import { AgentPanel } from "./panel.ts";
import { changed, finish, nextAgentId, onChange, pushLog, runningAgents, type Subagent, track } from "./registry.ts";

const THINKING: ThinkingLevel[] = ["off", "minimal", "low", "medium", "high", "xhigh", "max"];

const Params = Type.Object({
  task: Type.String({ description: "Complete, self-contained instructions. The subagent sees nothing of this conversation." }),
  name: Type.Optional(Type.String({ description: "Short label shown in the agents panel." })),
  model: Type.Optional(
    Type.String({ description: 'Model as "provider/id" or bare id. Defaults to the current model.' }),
  ),
  thinking: Type.Optional(
    StringEnum(THINKING, { description: "Thinking level. Defaults to the current level." }),
  ),
});

/** Resolve "provider/id" or bare id against models with working credentials. */
function resolveModel(ctx: ExtensionContext, spec: string | undefined) {
  if (!spec) {
    if (!ctx.model) throw new Error("No current model; pass `model`.");
    return ctx.model;
  }
  const available = ctx.modelRegistry.getAvailable();
  const hit =
    available.find((m) => `${m.provider}/${m.id}` === spec) ?? available.filter((m) => m.id === spec)[0];
  if (!hit) {
    const names = available.map((m) => `${m.provider}/${m.id}`).join(", ");
    throw new Error(`Unknown model "${spec}". Available: ${names}`);
  }
  return hit;
}

const oneLine = (v: unknown, n = 80) => {
  const s = typeof v === "string" ? v : JSON.stringify(v);
  const flat = (s ?? "").replace(/\s+/g, " ");
  return flat.length > n ? `${flat.slice(0, n - 1)}…` : flat;
};

export default function (pi: ExtensionAPI) {
  let unsubscribers: Array<() => void> = [];
  let panelOpen = false;

  async function openPanel(ctx: ExtensionContext) {
    if (panelOpen || ctx.mode !== "tui") return;
    panelOpen = true;
    try {
      await ctx.ui.custom<void>((tui, theme, _kb, done) => new AgentPanel(tui, theme, () => done()), {
        overlay: true,
        overlayOptions: { anchor: "bottom-center", width: "80%", minWidth: 40, maxHeight: "70%", margin: 1 },
      });
    } finally {
      panelOpen = false;
    }
  }

  pi.on("session_start", (_e, ctx) => {
    if (ctx.mode !== "tui") return;
    const refresh = () => {
      const n = runningAgents().length;
      ctx.ui.setStatus("subagents", n ? `● ${n} subagent${n > 1 ? "s" : ""} · ↑ to manage` : undefined);
    };
    unsubscribers = [
      onChange(refresh),
      ctx.ui.onTerminalInput((data) => {
        if (!matchesKey(data, "up") || ctx.ui.getEditorText() !== "" || !runningAgents().length) return;
        void openPanel(ctx);
        return { consume: true };
      }),
    ];
  });

  pi.on("session_shutdown", () => {
    for (const a of runningAgents()) a.cancel();
    for (const off of unsubscribers) off();
    unsubscribers = [];
  });

  pi.registerCommand("agents", {
    description: "Show subagents (steer / cancel)",
    handler: async (_a, ctx) => openPanel(ctx),
  });

  pi.registerTool({
    name: "subagent",
    label: "Subagent",
    description:
      "Delegate a self-contained task to an isolated subagent (fresh context, same tools, no subagent nesting) and return its final answer. " +
      "Choose `model` and `thinking` per task: cheaper/faster for search and summaries, stronger for hard reasoning. " +
      "Issue several calls in one message to run agents in parallel.",
    promptSnippet: "Delegate a task to an isolated subagent with a chosen model and thinking level",
    parameters: Params,
    executionMode: "parallel",
    async execute(_id, params, signal, onUpdate, ctx) {
      const model = resolveModel(ctx, params.model);
      const thinking = (params.thinking ?? ctx.thinkingLevel ?? "medium") as ThinkingLevel;
      const { session } = await createAgentSession({
        cwd: ctx.cwd,
        model,
        thinkingLevel: thinking,
        sessionManager: SessionManager.inMemory(),
        excludeTools: ["subagent"],
      });

      const id = nextAgentId();
      let cancelled = false;
      const agent: Subagent = {
        id,
        name: params.name ?? `agent-${id}`,
        task: params.task,
        model: `${model.provider}/${model.id}`,
        thinking: session.thinkingLevel,
        status: "running",
        startedAt: Date.now(),
        log: [],
        text: "",
        async steer(message) {
          pushLog(agent, `» ${oneLine(message)}`);
          changed();
          await session.steer(message);
        },
        cancel() {
          cancelled = true;
          void session.abort();
        },
      };
      track(agent);

      const unsubscribe = session.subscribe((e) => {
        if (e.type === "message_start") agent.text = "";
        else if (e.type === "message_update" && e.assistantMessageEvent.type === "text_delta")
          agent.text += e.assistantMessageEvent.delta;
        else if (e.type === "tool_execution_start") {
          pushLog(agent, `→ ${e.toolName} ${oneLine(e.args)}`);
          onUpdate?.({ content: [{ type: "text", text: `${agent.name}: ${e.toolName}` }], details: undefined });
        } else return;
        changed();
      });
      const onAbort = () => agent.cancel();
      signal?.addEventListener("abort", onAbort);

      try {
        await session.prompt(params.task);
        const text = session.getLastAssistantText() ?? "";
        if (cancelled || signal?.aborted) {
          finish(agent, "cancelled");
          return {
            content: [{ type: "text", text: `Subagent cancelled before finishing.${text ? `\nPartial output:\n${text}` : ""}` }],
            details: undefined,
          };
        }
        finish(agent, "done");
        return { content: [{ type: "text", text: text || "(subagent produced no text)" }], details: undefined };
      } catch (err) {
        finish(agent, "error");
        throw err;
      } finally {
        signal?.removeEventListener("abort", onAbort);
        unsubscribe();
        session.dispose();
      }
    },
  });
}
