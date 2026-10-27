import type { AssistantMessage, Message } from "@earendil-works/pi-ai";
import { getMarkdownTheme, type Theme } from "@earendil-works/pi-coding-agent";
import {
  type Component,
  Markdown,
  matchesKey,
  Text,
  type TUI,
  truncateToWidth,
  visibleWidth,
  wrapTextWithAnsi,
} from "@earendil-works/pi-tui";
import { type Run, type RunSummary, type Status, summarizeArgs } from "./runner.ts";

const SPINNER = ["⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"];

export function elapsed(summary: RunSummary): string {
  const seconds = Math.max(0, Math.round(((summary.endedAt ?? Date.now()) - summary.startedAt) / 1000));
  return seconds < 60 ? `${seconds}s` : `${Math.floor(seconds / 60)}m${String(seconds % 60).padStart(2, "0")}s`;
}

const tokens = (count: number) => (count < 1000 ? `${count}` : `${(count / 1000).toFixed(1)}k`);

/** `clock` animates. Leave it off in the transcript: a ticking line above the viewport clears scrollback. */
export function statusIcon(status: Status, theme: Theme, clock = false): string {
  if (status === "running") {
    const frame = clock ? SPINNER[Math.floor(Date.now() / 120) % SPINNER.length]! : "●";
    return theme.fg("accent", frame);
  }
  if (status === "completed") return theme.fg("success", "✓");
  if (status === "cancelled") return theme.fg("warning", "■");
  return theme.fg("error", "✗");
}

export function statsLine(summary: RunSummary, theme: Theme, clock = false): string {
  const parts = [
    summary.status === "running" && !clock ? "running" : elapsed(summary),
    `${summary.toolCalls} tool${summary.toolCalls === 1 ? "" : "s"}`,
    `↑${tokens(summary.tokens.input)} ↓${tokens(summary.tokens.output)}`,
  ];
  if (summary.cost > 0) parts.push(`$${summary.cost.toFixed(3)}`);
  return `${statusIcon(summary.status, theme, clock)} ${theme.fg("dim", parts.join(" · "))}`;
}

export function callLine(
  args: { agent?: string; description?: string; model?: string; thinking?: string; background?: boolean; readonly?: boolean; worktree?: boolean; sessionID?: string },
  theme: Theme,
): string {
  const flags = [
    args.model && `${args.model}${args.thinking ? `:${args.thinking}` : ""}`,
    !args.model && args.thinking,
    args.background && "background",
    args.readonly && "read-only",
    args.worktree && "worktree",
    args.sessionID && "resume",
  ].filter(Boolean);
  return [
    theme.fg("toolTitle", theme.bold("subagent ")),
    theme.fg("accent", args.agent ?? "…"),
    args.description ? ` ${args.description}` : "",
    flags.length ? theme.fg("dim", ` (${flags.join(", ")})`) : "",
  ].join("");
}

/** Status, the last few tool calls, and the output, as one block for tool cards and messages. */
export function summaryLines(summary: RunSummary, expanded: boolean, theme: Theme, width: number): string[] {
  const lines = [statsLine(summary, theme)];
  if (summary.status === "running") {
    for (const item of summary.activity.slice(-4)) lines.push(theme.fg("dim", `  → ${item}`));
    lines.push(theme.fg("dim", `  /subagents ${summary.sessionID.slice(-8)} to watch`));
    return lines.map((line) => truncateToWidth(line, width));
  }
  if (summary.status === "error") lines.push(theme.fg("error", summary.error ?? "failed"));
  const output = summary.output?.trim();
  if (output) {
    const rendered = new Markdown(output, 0, 0, getMarkdownTheme()).render(width);
    const shown = expanded ? rendered : rendered.slice(0, 8);
    lines.push(...shown);
    if (shown.length < rendered.length) lines.push(theme.fg("dim", `  … ${rendered.length - shown.length} more lines`));
  }
  if (summary.worktree?.kept) lines.push(theme.fg("warning", `  changes kept in ${summary.worktree.path}`));
  return lines.map((line) => truncateToWidth(line, width));
}

export class Lines implements Component {
  constructor(private draw: (width: number) => string[]) {}
  render(width: number) {
    return this.draw(width);
  }
  invalidate() {}
}

/** One line per running subagent, shown above the editor. No animation timer: a rewrite snaps scrollback. */
export function widget(
  runs: () => Run[],
  tui: TUI,
  theme: Theme,
  onIdle: () => void,
): Component & { dispose(): void } {
  const unsubs = new Map<string, () => void>();
  let signature = "";
  const running = () => runs().filter((run) => run.summary.status === "running");
  const signatureOf = () => running().map((run) => `${run.summary.sessionID}:${run.summary.toolCalls}:${run.summary.activity.at(-1) ?? ""}`).join("\n");
  const sync = () => {
    const active = running();
    const ids = new Set(active.map((run) => run.summary.sessionID));
    for (const [id, off] of unsubs) {
      if (!ids.has(id)) {
        off();
        unsubs.delete(id);
      }
    }
    for (const run of active) {
      if (unsubs.has(run.summary.sessionID)) continue;
      unsubs.set(
        run.summary.sessionID,
        run.onChange(() => {
          if (running().length === 0) {
            onIdle();
            return;
          }
          const next = signatureOf();
          if (next === signature) return;
          signature = next;
          sync();
          tui.requestRender();
        }),
      );
    }
  };
  return {
    render(width) {
      sync();
      return running().map((run) => {
        const s = run.summary;
        const last = s.activity.at(-1);
        return truncateToWidth(
          `${theme.fg("accent", "●")} ${theme.fg("accent", s.agent)} ${s.description}${last ? theme.fg("dim", ` · ${last}`) : ""}`,
          width,
        );
      });
    },
    invalidate() {},
    dispose() {
      for (const off of unsubs.values()) off();
      unsubs.clear();
    },
  };
}

function messageLines(message: Message | AssistantMessage, theme: Theme, width: number): string[] {
  const out: string[] = [];
  const wrap = (text: string, style: (s: string) => string, prefix = "") =>
    wrapTextWithAnsi(text, Math.max(10, width - visibleWidth(prefix))).map((line) => prefix + style(line));
  if (message.role === "user") {
    const text = typeof message.content === "string" ? message.content : message.content.map((part) => (part.type === "text" ? part.text : "")).join("");
    const lines = text.split("\n");
    out.push(...wrap(lines.slice(0, 12).join("\n"), (s) => theme.fg("muted", s), theme.fg("accent", "› ")));
    if (lines.length > 12) out.push(theme.fg("dim", `  … ${lines.length - 12} more lines`));
  } else if (message.role === "assistant") {
    for (const part of message.content) {
      if (part.type === "text" && part.text.trim()) out.push(...new Markdown(part.text, 0, 0, getMarkdownTheme()).render(width));
      else if (part.type === "thinking" && part.thinking.trim()) out.push(theme.fg("dim", theme.italic("  thinking…")));
      else if (part.type === "toolCall") out.push(theme.fg("toolTitle", `→ ${summarizeArgs(part.name, part.arguments)}`));
    }
  } else if (message.role === "toolResult") {
    const text = message.content.map((part) => (part.type === "text" ? part.text : "[image]")).join("").trim();
    const first = text.split("\n")[0] ?? "";
    const more = text.split("\n").length - 1;
    const line = `  ${message.isError ? "✗" : "✓"} ${first}${more > 0 ? ` (+${more} lines)` : ""}`;
    out.push(message.isError ? theme.fg("error", line) : theme.fg("dim", line));
  }
  return out.map((line) => truncateToWidth(line, width));
}

export type ViewerAction = "close" | "back" | "steer" | "abort";

/** Full-height overlay with the child's live transcript. */
export class Viewer implements Component {
  private scroll = 0;
  private follow = true;
  private cache?: { key: string; lines: string[] };
  private unsubscribe?: () => void;

  constructor(
    private tui: TUI,
    private theme: Theme,
    private summary: () => RunSummary,
    private messages: () => (Message | AssistantMessage)[],
    private live: Run | undefined,
    private done: (action: ViewerAction) => void,
  ) {
    this.unsubscribe = live?.onChange(() => tui.requestRender());
  }

  dispose() {
    this.unsubscribe?.();
  }

  invalidate() {
    this.cache = undefined;
  }

  private bodyHeight() {
    return Math.max(5, Math.floor(this.tui.terminal.rows * 0.85) - 7);
  }

  private body(width: number): string[] {
    const messages = this.messages();
    const streaming = this.live?.streaming;
    const key = `${width}:${messages.length}:${JSON.stringify(streaming?.content ?? "").length}`;
    if (this.cache?.key === key) return this.cache.lines;
    const lines: string[] = [];
    for (const message of streaming ? [...messages, streaming] : messages) {
      const rendered = messageLines(message, this.theme, width);
      if (rendered.length) lines.push(...rendered, "");
    }
    this.cache = { key, lines };
    return lines;
  }

  handleInput(data: string) {
    const page = this.bodyHeight() - 2;
    const move = (delta: number) => {
      this.follow = false;
      this.scroll = Math.max(0, this.scroll + delta);
    };
    if (matchesKey(data, "escape") || data === "q") this.done("back");
    else if (matchesKey(data, "ctrl+c")) this.done("close");
    else if (matchesKey(data, "up") || data === "k") move(-1);
    else if (matchesKey(data, "down") || data === "j") move(1);
    else if (matchesKey(data, "pageUp") || matchesKey(data, "ctrl+u")) move(-page);
    else if (matchesKey(data, "pageDown") || matchesKey(data, "ctrl+d") || data === " ") move(page);
    else if (matchesKey(data, "home") || data === "g") move(-Infinity);
    else if (matchesKey(data, "end") || data === "G") this.follow = true;
    else if (data === "s" && this.summary().status === "running") this.done("steer");
    else if (data === "x" && this.summary().status === "running") this.done("abort");
    else return;
    this.tui.requestRender();
  }

  render(width: number): string[] {
    const th = this.theme;
    const s = this.summary();
    const inner = Math.max(20, width - 4);
    const height = this.bodyHeight();
    const body = this.body(inner);
    const maxScroll = Math.max(0, body.length - height);
    if (this.follow || this.scroll >= maxScroll) {
      this.scroll = maxScroll;
      this.follow = true;
    }
    const visible = body.slice(this.scroll, this.scroll + height);
    while (visible.length < height) visible.push("");

    const border = (text: string) => th.fg("border", text);
    const row = (text: string) => {
      const clipped = truncateToWidth(text, inner);
      return `${border("│")} ${clipped}${" ".repeat(Math.max(0, inner - visibleWidth(clipped)))} ${border("│")}`;
    };
    const title = ` ${s.agent} · ${s.description} `;
    const position = body.length > height ? ` ${Math.round(((this.scroll + height) / body.length) * 100)}% ` : "";
    const keys = [
      "↑↓/jk scroll",
      "g/G top/end",
      ...(s.status === "running" ? ["s steer", "x abort"] : []),
      "esc back",
    ].join(" · ");
    return [
      border(`╭─${truncateToWidth(th.bold(title), inner - 2)}${"─".repeat(Math.max(0, inner - visibleWidth(title) - 1))}╮`),
      row(`${statsLine(s, th, true)} ${th.fg("dim", `· ${s.model}:${s.thinking}${s.readonly ? " · read-only" : ""}`)}`),
      row(th.fg("dim", `${s.cwd} · ${s.sessionID}`)),
      border(`├${"─".repeat(inner + 2)}┤`),
      ...visible.map(row),
      border(`├${"─".repeat(inner + 2)}┤`),
      row(th.fg("dim", keys)),
      border(`╰${"─".repeat(Math.max(0, inner + 2 - visibleWidth(position)))}${position}╯`),
    ];
  }
}

export function textComponent(text: string) {
  return new Text(text, 0, 0);
}
