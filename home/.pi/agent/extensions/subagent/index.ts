/**
 * Subagents for pi, modeled on opencode's `subagent` tool.
 *
 * Each subagent is a child pi session in this process, saved next to the parent
 * session (it shows nested under it in /resume). The model resumes one by passing
 * its sessionID. Background results arrive as a follow-up message. /subagents opens
 * a live transcript of any child, where you can steer or abort it.
 */

import { getSupportedThinkingLevels, StringEnum, type Usage } from "@earendil-works/pi-ai";
import { type ExtensionAPI, type ExtensionContext, SessionManager } from "@earendil-works/pi-coding-agent";
import { Text } from "@earendil-works/pi-tui";
import { isAbsolute, resolve } from "node:path";
import { Type } from "typebox";
import { discoverAgents, THINKING_LEVELS, type Thinking } from "./agents.ts";
import { Run, type RunSummary, resultText } from "./runner.ts";
import { callLine, elapsed, Lines, summaryLines, Viewer, type ViewerAction, widget } from "./ui.ts";

export default function (pi: ExtensionAPI) {
  const runs = new Map<string, Run>();
  const known = new Map<string, RunSummary>();
  const cards = new Map<string, () => void>();
  let current: ExtensionContext | undefined;
  let widgetShown = false;

  const backgroundRunning = () => [...runs.values()].filter((run) => run.summary.background && run.summary.status === "running");

  const refreshWidget = () => {
    if (!current?.hasUI || current.mode !== "tui") return;
    const show = backgroundRunning().length > 0;
    if (show === widgetShown) return;
    widgetShown = show;
    current.ui.setWidget("subagents", show ? (tui, theme) => widget(backgroundRunning, tui, theme) : undefined);
  };

  const resolveModel = (ref: string, ctx: ExtensionContext) => {
    const slash = ref.indexOf("/");
    if (slash < 1) throw new Error(`Invalid model "${ref}". Use "provider/model", such as "anthropic/claude-sonnet-4-5".`);
    const model = ctx.modelRegistry.find(ref.slice(0, slash), ref.slice(slash + 1));
    if (!model || !ctx.modelRegistry.hasConfiguredAuth(model)) {
      const available = ctx.modelRegistry
        .getAvailable()
        .map((candidate) => `${candidate.provider}/${candidate.id}`)
        .slice(0, 40);
      throw new Error(`Model "${ref}" is not available. Available models: ${available.join(", ")}.`);
    }
    return model;
  };

  const all = (): RunSummary[] => {
    const merged = new Map(known);
    for (const [id, run] of runs) merged.set(id, run.summary);
    return [...merged.values()].sort((a, b) => b.startedAt - a.startedAt);
  };

  const agentList = discoverAgents(process.cwd(), false)
    .map((agent) => `- ${agent.name}: ${agent.description || "Only use when explicitly requested."}`)
    .join("\n");

  pi.registerTool({
    name: "subagent",
    label: "Subagent",
    description: [
      "Spawns an agent in a child pi session to work on a task.",
      "The result includes a sessionID. Pass it back as sessionID to continue that subagent's conversation.",
      "New subagents start with fresh context, so put everything they need in the prompt.",
      "Foreground (the default) waits and returns the subagent's final message. background: true returns at once, and the result arrives as a message when the subagent finishes. Do not sleep or poll while you wait.",
      "Several subagent calls in one message run in parallel.",
      "readonly: true blocks file changes. worktree: true runs the subagent in a new git worktree from HEAD and keeps the worktree only if it changed something. cwd sets its working folder.",
      "",
      "Available agents (more may be defined in .pi/agents/ of the project):",
      agentList,
    ].join("\n"),
    parameters: Type.Object({
      agent: Type.String({ description: "The agent to run, from the list of available agents." }),
      description: Type.String({ description: "A short 3-5 word label for the task, shown to the user." }),
      prompt: Type.String({ description: "The task for the subagent." }),
      model: Type.Optional(
        Type.String({
          description:
            'Model as "provider/model". Leave unset to use the agent\'s model or this session\'s model. Do not guess IDs.',
        }),
      ),
      thinking: Type.Optional(StringEnum(THINKING_LEVELS, { description: "Reasoning level for the subagent." })),
      sessionID: Type.Optional(Type.String({ description: "Continue an earlier subagent by its sessionID." })),
      background: Type.Optional(Type.Boolean({ description: "Run without waiting. You are notified when it finishes." })),
      readonly: Type.Optional(Type.Boolean({ description: "Block edits, writes, and shell commands that change files." })),
      cwd: Type.Optional(Type.String({ description: "Working folder, absolute or relative to yours." })),
      worktree: Type.Optional(Type.Boolean({ description: "Run in a new git worktree checked out from HEAD." })),
    }),

    async execute(_toolCallId, params, signal, onUpdate, ctx) {
      let run = params.sessionID ? runs.get(params.sessionID) : undefined;
      const prior = run?.summary ?? (params.sessionID ? known.get(params.sessionID) : undefined);
      if (params.sessionID && !prior) throw new Error(`No subagent with sessionID ${params.sessionID} in this session.`);
      if (prior && params.agent !== prior.agent) {
        throw new Error(`Subagent ${prior.sessionID} is a "${prior.agent}" agent. Resume it with agent "${prior.agent}".`);
      }

      const agents = discoverAgents(ctx.cwd, ctx.isProjectTrusted());
      const agent = agents.find((candidate) => candidate.name === params.agent);
      if (!agent) {
        throw new Error(`Unknown agent "${params.agent}". Available: ${agents.map((candidate) => candidate.name).join(", ")}.`);
      }

      const modelRef = params.model ?? prior?.model ?? agent.model;
      const model = modelRef ? resolveModel(modelRef, ctx) : ctx.model;
      if (!model) throw new Error("This session has no model. Pass model as provider/model.");
      const supported = getSupportedThinkingLevels(model) as string[];
      if (params.thinking && !supported.includes(params.thinking)) {
        throw new Error(`${model.provider}/${model.id} supports thinking levels ${supported.join(", ")}, not ${params.thinking}.`);
      }
      const wanted = params.thinking ?? (prior?.thinking as Thinking | undefined) ?? agent.thinking ?? ctx.thinkingLevel ?? "medium";
      const thinking = (supported.includes(wanted) ? wanted : (supported.at(-1) ?? "off")) as Thinking;
      const background = params.background === true;

      if (run) {
        if (params.model) await run.session.setModel(model);
        if (params.thinking) run.session.setThinkingLevel(thinking);
        run.summary.model = `${model.provider}/${model.id}`;
        run.summary.thinking = thinking;
        run.summary.background = background;
      } else {
        const cwd = params.cwd ? (isAbsolute(params.cwd) ? params.cwd : resolve(ctx.cwd, params.cwd)) : ctx.cwd;
        run = await Run.spawn(ctx, {
          agent,
          description: prior?.description ?? params.description,
          model,
          thinking,
          cwd: prior?.cwd ?? cwd,
          readonly: prior?.readonly ?? (agent.readonly || params.readonly === true),
          background,
          worktree: params.worktree === true,
          resume: prior,
        });
        runs.set(run.summary.sessionID, run);
      }

      const child = run;
      const before = { ...child.summary.tokens, cost: child.summary.cost };
      const sent = child.send(params.prompt);
      known.set(child.summary.sessionID, child.summary);
      refreshWidget();
      // A saved child is closed once it settles, so it holds no MCP connections while idle.
      // Viewing reads its file, and resuming reopens it.
      const finished = sent.then(async () => {
        if (!child.summary.sessionFile || child.summary.status === "running") return;
        known.set(child.summary.sessionID, structuredClone(child.summary));
        if (runs.get(child.summary.sessionID) === child) runs.delete(child.summary.sessionID);
        await child.dispose();
      });

      if (background) {
        void finished.then(() => {
          refreshWidget();
          if (current === undefined) return;
          const summary = structuredClone(child.summary);
          known.set(summary.sessionID, summary);
          void pi.sendMessage(
            { customType: "subagent", content: resultText(summary), display: true, details: summary },
            { triggerTurn: true, deliverAs: "followUp" },
          );
        });
        return {
          content: [
            {
              type: "text",
              text: [
                `The subagent is working in the background (sessionID: ${child.summary.sessionID}). You will be notified automatically when it finishes.`,
                "Do not sleep, poll, or duplicate its work. Work on something else, or tell the user what you started and end your turn.",
              ].join("\n"),
            },
          ],
          details: structuredClone(child.summary),
        };
      }

      const update = () => onUpdate?.({ content: [{ type: "text", text: "running" }], details: structuredClone(child.summary) });
      let pending = false;
      const off = child.onChange(() => {
        if (pending) return;
        pending = true;
        setTimeout(() => {
          pending = false;
          update();
        }, 150);
      });
      const ticker = setInterval(update, 1000);
      const stop = () => void child.abort();
      signal?.addEventListener("abort", stop, { once: true });
      try {
        await finished;
      } finally {
        off();
        clearInterval(ticker);
        signal?.removeEventListener("abort", stop);
      }

      const summary = structuredClone(child.summary);
      const cost = summary.cost - before.cost;
      const usage: Usage = {
        input: summary.tokens.input - before.input,
        output: summary.tokens.output - before.output,
        cacheRead: 0,
        cacheWrite: 0,
        totalTokens: summary.tokens.input - before.input + summary.tokens.output - before.output,
        cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0, total: cost },
      };
      return {
        content: [{ type: "text", text: resultText(summary) }],
        details: summary,
        usage,
        ...(summary.status === "completed" ? {} : { isError: true }),
      };
    },

    renderCall(args, theme) {
      return new Text(callLine(args, theme), 0, 0);
    },

    renderResult(result, { expanded }, theme, context) {
      const details = result.details as RunSummary | undefined;
      if (!details?.sessionID) {
        const text = result.content.find((part) => part.type === "text");
        return new Text(text?.type === "text" ? theme.fg("error", text.text) : "", 0, 0);
      }
      const live = runs.get(details.sessionID);
      // A background card stays in history. Rewriting it while the child streams changes a line
      // above the viewport, and regular mode then clears scrollback on every frame.
      const summary =
        details.background && (!live || live.summary.status === "running")
          ? details
          : (live?.summary ?? known.get(details.sessionID) ?? details);
      if (details.background && live && live.summary.status === "running" && !cards.has(context.toolCallId)) {
        const off = live.onChange(() => {
          if (live.summary.status === "running") return;
          off();
          cards.delete(context.toolCallId);
          context.invalidate();
        });
        cards.set(context.toolCallId, off);
      }
      return new Lines((width) => {
        if (!summary.background) return summaryLines(summary, expanded, theme, width);
        const lines = summaryLines({ ...summary, output: undefined, worktree: undefined }, false, theme, width);
        if (summary.status !== "running") lines[0] += theme.fg("dim", " · result delivered below");
        return lines;
      });
    },
  });

  pi.registerMessageRenderer<RunSummary>("subagent", (message, { expanded }, theme) => {
    const summary = message.details;
    if (!summary) return undefined;
    return new Lines((width) =>
      [
        `${callLine({ agent: summary.agent, description: summary.description }, theme)}${theme.fg("dim", " finished in the background")}`,
        ...summaryLines(summary, expanded, theme, width - 1),
      ].map((line) => ` ${line}`),
    );
  });

  const view = (ctx: ExtensionContext, id: string) => {
    const live = runs.get(id);
    const summary = () => live?.summary ?? known.get(id)!;
    let stored: ReturnType<SessionManager["buildSessionContext"]>["messages"] | undefined;
    const messages = () => {
      if (live) return live.session.messages as never;
      const file = summary().sessionFile;
      stored ??= file ? SessionManager.open(file).buildSessionContext().messages : [];
      return stored as never;
    };
    return ctx.ui.custom<ViewerAction>(
      (tui, theme, _keybindings, done) => new Viewer(tui, theme, summary, messages, live, done),
      { overlay: true, overlayOptions: { width: "92%", maxHeight: "92%" } },
    );
  };

  pi.registerCommand("subagents", {
    description: "Watch, steer, or abort this session's subagents",
    getArgumentCompletions: (prefix) =>
      all()
        .map((s) => ({ value: s.sessionID.slice(-8), label: `${s.sessionID.slice(-8)} ${s.agent} · ${s.description}` }))
        .filter((item) => item.value.startsWith(prefix.trim())),
    handler: async (args, ctx) => {
      const list = all();
      if (list.length === 0) {
        ctx.ui.notify("No subagents in this session yet.", "info");
        return;
      }
      const label = (s: RunSummary) =>
        `${{ running: "●", completed: "✓", error: "✗", cancelled: "■" }[s.status]} ${s.agent} · ${s.description} · ${elapsed(s)} · ${s.sessionID.slice(-8)}`;
      if (!ctx.hasUI || ctx.mode !== "tui") {
        ctx.ui.notify(list.map(label).join("\n"), "info");
        return;
      }
      const direct = args.trim() ? list.find((s) => s.sessionID.endsWith(args.trim()) || s.sessionID === args.trim())?.sessionID : undefined;
      let id = direct ?? (list.length === 1 ? list[0]!.sessionID : undefined);
      for (;;) {
        if (!id) {
          const options = all();
          const labels = options.map(label);
          const pick = await ctx.ui.select("Subagents", labels);
          id = pick ? options[labels.indexOf(pick)]?.sessionID : undefined;
          if (!id) return;
        }
        const action = await view(ctx, id);
        const run = runs.get(id);
        if (action === "close") return;
        if (action === "back") {
          if (direct || all().length === 1) return;
          id = undefined;
        } else if (action === "steer" && run) {
          const text = await ctx.ui.input("Steer subagent", "Message the subagent reads after its current step");
          if (text?.trim()) await run.session.steer(text.trim());
        } else if (action === "abort" && run && (await ctx.ui.confirm("Abort subagent?", run.summary.description))) {
          await run.abort();
        }
      }
    },
  });

  pi.on("session_start", (_event, ctx) => {
    current = ctx;
    known.clear();
    for (const entry of ctx.sessionManager.getBranch() as Array<Record<string, any>>) {
      const details =
        entry.type === "message" && entry.message?.role === "toolResult" && entry.message.toolName === "subagent"
          ? entry.message.details
          : entry.type === "custom_message" && entry.customType === "subagent"
            ? entry.details
            : undefined;
      if (!details?.sessionID) continue;
      // A child that was still running when pi exited can be resumed, but isn't running now.
      known.set(details.sessionID, details.status === "running" ? { ...details, status: "cancelled" } : details);
    }
  });

  pi.on("session_shutdown", async () => {
    current = undefined;
    for (const off of cards.values()) off();
    cards.clear();
    await Promise.allSettled([...runs.values()].map((run) => run.abort()));
    await Promise.allSettled([...runs.values()].map((run) => run.dispose()));
    runs.clear();
    widgetShown = false;
  });
}
);
    widgetShown = false;
  });
}
