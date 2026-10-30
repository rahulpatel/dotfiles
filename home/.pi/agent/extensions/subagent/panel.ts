/** Overlay listing subagents: ↑/↓ select, s steer, x cancel, esc close. */
import type { Theme } from "@earendil-works/pi-coding-agent";
import { type Component, type Focusable, matchesKey, truncateToWidth, wrapTextWithAnsi } from "@earendil-works/pi-tui";
import { allAgents, onChange, type Subagent } from "./registry.ts";

const DETAIL_LINES = 10;
const secs = (a: Subagent) => `${Math.round(((a.endedAt ?? Date.now()) - a.startedAt) / 1000)}s`;

export class AgentPanel implements Component, Focusable {
  focused = false;
  private selectedId: number | undefined;
  private input: string | undefined; // defined while typing a steering message
  private unsubscribe: () => void;
  private tick: ReturnType<typeof setInterval>;

  constructor(
    private tui: { requestRender(): void },
    private theme: Theme,
    private done: () => void,
  ) {
    this.unsubscribe = onChange(() => this.tui.requestRender());
    this.tick = setInterval(() => this.tui.requestRender(), 1000);
    this.selectedId = allAgents().find((a) => a.status === "running")?.id ?? allAgents()[0]?.id;
  }

  dispose(): void {
    this.unsubscribe();
    clearInterval(this.tick);
  }

  invalidate(): void {}

  private selected(): Subagent | undefined {
    const list = allAgents();
    return list.find((a) => a.id === this.selectedId) ?? list[0];
  }

  private move(delta: number): void {
    const list = allAgents();
    if (!list.length) return;
    const i = Math.max(0, list.findIndex((a) => a.id === this.selected()?.id));
    this.selectedId = list[(i + delta + list.length) % list.length]!.id;
  }

  handleInput(data: string): void {
    const agent = this.selected();
    if (this.input !== undefined) {
      if (matchesKey(data, "escape")) this.input = undefined;
      else if (matchesKey(data, "return")) {
        const msg = this.input.trim();
        this.input = undefined;
        if (msg && agent?.status === "running") void agent.steer(msg);
      } else if (matchesKey(data, "backspace")) this.input = this.input.slice(0, -1);
      else if (!/[\x00-\x1f\x7f]/.test(data) && !data.startsWith("\x1b")) this.input += data;
    } else if (matchesKey(data, "escape") || data === "q") this.done();
    else if (matchesKey(data, "up") || data === "k") this.move(-1);
    else if (matchesKey(data, "down") || data === "j") this.move(1);
    else if ((data === "s" || matchesKey(data, "return")) && agent?.status === "running") this.input = "";
    else if (data === "x" && agent?.status === "running") agent.cancel();
    this.tui.requestRender();
  }

  render(width: number): string[] {
    const th = this.theme;
    const w = Math.max(20, width - 2);
    const row = (s: string) => th.fg("border", "│") + truncateToWidth(s, w, "", true) + th.fg("border", "│");
    const list = allAgents();
    const sel = this.selected();
    const icon = (a: Subagent) =>
      a.status === "running" ? th.fg("accent", "●") : a.status === "done" ? th.fg("success", "✓") : th.fg("error", a.status === "error" ? "✗" : "⊘");

    const out = [th.fg("border", `╭${"─".repeat(w)}╮`), row(` ${th.bold(th.fg("accent", "Subagents"))}`)];
    if (!list.length) out.push(row(th.fg("dim", " none")));
    for (const a of list) {
      const active = a.id === sel?.id;
      const line = ` ${active ? th.fg("accent", "▸") : " "} ${icon(a)} ${active ? th.bold(a.name) : a.name} ${th.fg("dim", `${a.model} · ${a.thinking} · ${secs(a)}`)}`;
      out.push(row(line));
    }
    if (sel) {
      out.push(row(""), row(th.fg("dim", ` task: ${sel.task.replace(/\s+/g, " ")}`)));
      const body = [...sel.log.map((l) => th.fg("muted", l)), ...(sel.text ? sel.text.split("\n") : [])];
      const lines = body.flatMap((l) => wrapTextWithAnsi(l, w - 2)).slice(-DETAIL_LINES);
      for (const l of lines) out.push(row(` ${l}`));
    }
    out.push(row(""));
    out.push(
      row(
        this.input !== undefined
          ? ` ${th.fg("accent", "steer ›")} ${this.input}${th.fg("dim", "▏")}  ${th.fg("dim", "enter send · esc back")}`
          : th.fg("dim", " ↑↓ select · s steer · x cancel · esc close"),
      ),
    );
    out.push(th.fg("border", `╰${"─".repeat(w)}╯`));
    return out;
  }
}
