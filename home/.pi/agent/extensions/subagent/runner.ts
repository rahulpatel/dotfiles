import { execFileSync } from "node:child_process";
import { randomUUID } from "node:crypto";
import { existsSync, mkdirSync } from "node:fs";
import { tmpdir } from "node:os";
import { basename, join, relative } from "node:path";
import type { AssistantMessage } from "@earendil-works/pi-ai";
import {
  type AgentSession,
  type AgentSessionEvent,
  createAgentSession,
  createBashTool,
  createCodemodeExtension,
  createMcpExtension,
  createToolSearchExtension,
  DefaultResourceLoader,
  type ExtensionContext,
  type ExtensionFactory,
  getAgentDir,
  SessionManager,
  SettingsManager,
} from "@earendil-works/pi-coding-agent";
import type { AgentConfig, Thinking } from "./agents.ts";

export type Status = "running" | "completed" | "error" | "cancelled";

export interface Worktree {
  root: string;
  path: string;
  branch: string;
  base: string;
  kept?: boolean;
  dirty?: boolean;
}

/** Plain JSON: stored in tool-result details and used to resume or view a child after a restart. */
export interface RunSummary {
  sessionID: string;
  sessionFile?: string;
  agent: string;
  description: string;
  model: string;
  thinking: string;
  cwd: string;
  readonly: boolean;
  background: boolean;
  worktree?: Worktree;
  status: Status;
  startedAt: number;
  endedAt?: number;
  toolCalls: number;
  tokens: { input: number; output: number };
  cost: number;
  activity: string[];
  output?: string;
  error?: string;
}

export interface SpawnOptions {
  agent: AgentConfig;
  description: string;
  model: NonNullable<ExtensionContext["model"]>;
  thinking: Thinking;
  cwd: string;
  readonly: boolean;
  background: boolean;
  worktree: boolean;
  resume?: RunSummary;
}

const READ_ONLY_TOOLS = new Set(["read", "grep", "find", "ls", "codemode", "tool_search"]);

// Writes are denied everywhere except temp folders and devices, so `git diff`
// and test runs work, but nothing in the workspace or home folder changes.
const SANDBOX_PROFILE = [
  "(version 1)",
  "(allow default)",
  "(deny file-write*)",
  '(allow file-write* (literal "/dev/null") (literal "/dev/zero") (literal "/dev/tty") (literal "/dev/dtracehelper")',
  '  (regex #"^/dev/fd/") (regex #"^/dev/ttys") (subpath "/private/tmp") (subpath "/private/var/folders"))',
].join("\n");

const shellQuote = (text: string) => `'${text.replace(/'/g, `'\\''`)}'`;

function readonlyExtension(cwd: string): ExtensionFactory {
  return (pi) => {
    const sandboxed = process.platform === "darwin";
    if (sandboxed) {
      const bash = createBashTool(cwd, {
        spawnHook: (spawn) => ({
          ...spawn,
          command: `exec /usr/bin/sandbox-exec -p ${shellQuote(SANDBOX_PROFILE)} /bin/bash -c ${shellQuote(spawn.command)}`,
        }),
      });
      pi.registerTool({
        ...bash,
        execute: (id, params, signal, onUpdate) => bash.execute(id, params, signal, onUpdate),
      });
    }
    pi.on("tool_call", (event) => {
      if (READ_ONLY_TOOLS.has(event.toolName)) return;
      if (event.toolName === "bash" && sandboxed) return;
      const tool = pi.getAllTools().find((candidate) => candidate.name === event.toolName);
      if (tool?.annotations?.readOnlyHint === true) return;
      return { block: true, reason: `This subagent is read-only, so it cannot use ${event.toolName}.` };
    });
  };
}

function git(cwd: string, ...args: string[]) {
  return execFileSync("git", ["-C", cwd, ...args], { encoding: "utf8", stdio: ["ignore", "pipe", "pipe"] }).trim();
}

function createWorktree(cwd: string): { worktree: Worktree; cwd: string } {
  const root = git(cwd, "rev-parse", "--show-toplevel");
  const base = git(root, "rev-parse", "HEAD");
  const id = randomUUID().slice(0, 8);
  const dir = join(tmpdir(), "pi-subagents");
  mkdirSync(dir, { recursive: true });
  const path = join(dir, `${basename(root)}-${id}`);
  const branch = `subagent/${id}`;
  git(root, "worktree", "add", "-q", "-b", branch, path, base);
  return { worktree: { root, path, branch, base }, cwd: join(path, relative(root, cwd)) };
}

/** Removes a worktree the child left unchanged. Keeps it, and says so, when it has changes. */
function settleWorktree(worktree: Worktree) {
  if (!existsSync(worktree.path)) return;
  worktree.dirty = git(worktree.path, "status", "--porcelain") !== "";
  const moved = git(worktree.path, "rev-parse", "HEAD") !== worktree.base;
  worktree.kept = worktree.dirty || moved;
  if (worktree.kept) return;
  git(worktree.root, "worktree", "remove", "--force", worktree.path);
  git(worktree.root, "branch", "-D", worktree.branch);
}

export function summarizeArgs(tool: string, args: unknown): string {
  const input = (args ?? {}) as Record<string, unknown>;
  const pick = (input.command ?? input.path ?? input.file_path ?? input.pattern ?? input.query ?? input.url) as
    | string
    | undefined;
  const text = pick ?? JSON.stringify(input);
  const line = String(text).split("\n")[0] ?? "";
  return `${tool} ${line.length > 80 ? `${line.slice(0, 79)}…` : line}`.trim();
}

const SUBAGENT_PROMPT = [
  "You are a subagent spawned by another pi session to do one task.",
  "The other session sees only your final message, so make it complete and self-contained.",
  "You cannot ask the user questions. If you are blocked, explain what you need in your final message.",
].join("\n");

export class Run {
  summary: RunSummary;
  session: AgentSession;
  streaming?: AssistantMessage;
  done: Promise<void> = Promise.resolve();
  private aborted = false;
  private listeners = new Set<() => void>();

  private constructor(session: AgentSession, summary: RunSummary) {
    this.session = session;
    this.summary = summary;
    session.subscribe((event) => this.handle(event));
  }

  static async spawn(ctx: ExtensionContext, options: SpawnOptions): Promise<Run> {
    const { agent, resume } = options;
    let cwd = options.cwd;
    let worktree = resume?.worktree;
    if (resume) {
      if (!existsSync(cwd)) throw new Error(`The subagent's folder ${cwd} no longer exists. Start a new subagent.`);
    } else if (options.worktree) {
      ({ worktree, cwd } = createWorktree(cwd));
    }

    const agentDir = getAgentDir();
    const settingsManager = SettingsManager.create(cwd, agentDir, { projectTrusted: ctx.isProjectTrusted() });
    const loader = new DefaultResourceLoader({
      cwd,
      agentDir,
      settingsManager,
      extensionFactories: [
        { name: "codemode", factory: createCodemodeExtension(), builtin: true, replaceable: true },
        { name: "tool-search", factory: createToolSearchExtension(), builtin: true, replaceable: true },
        { name: "mcp", factory: createMcpExtension(), builtin: true, replaceable: true },
        ...(options.readonly ? [{ name: "subagent-readonly", factory: readonlyExtension(cwd) }] : []),
      ],
      // Subagents don't spawn subagents.
      extensionsOverride: (base) => ({
        ...base,
        extensions: base.extensions.filter((extension) => !extension.tools.has("subagent")),
      }),
      ...(agent.promptMode === "replace" ? { systemPrompt: agent.prompt } : {}),
      appendSystemPrompt: [SUBAGENT_PROMPT, ...(agent.promptMode === "append" && agent.prompt ? [agent.prompt] : [])],
    });
    await loader.reload();

    const parentFile = ctx.sessionManager.getSessionFile();
    const sessionManager = resume?.sessionFile
      ? SessionManager.open(resume.sessionFile)
      : parentFile
        ? SessionManager.create(cwd, ctx.sessionManager.getSessionDir(), { parentSession: parentFile })
        : SessionManager.inMemory(cwd);

    const modelRuntime = (ctx.modelRegistry as unknown as { runtime?: never }).runtime;
    const { session } = await createAgentSession({
      cwd,
      agentDir,
      sessionManager,
      settingsManager,
      resourceLoader: loader,
      ...(modelRuntime ? { modelRuntime } : {}),
      model: options.model,
      thinkingLevel: options.thinking,
      ...(options.readonly ? { excludeTools: ["edit", "write"] } : {}),
    });
    if (!resume) session.setSessionName(`${agent.name}: ${options.description}`);
    await session.bindExtensions({});

    return new Run(session, {
      sessionID: session.sessionId,
      sessionFile: session.sessionFile,
      agent: agent.name,
      description: options.description,
      model: `${options.model.provider}/${options.model.id}`,
      thinking: options.thinking,
      cwd,
      readonly: options.readonly,
      background: options.background,
      worktree,
      status: "running",
      startedAt: Date.now(),
      toolCalls: resume?.toolCalls ?? 0,
      tokens: resume?.tokens ?? { input: 0, output: 0 },
      cost: resume?.cost ?? 0,
      activity: [],
    });
  }

  /** Starts a turn, or steers the child when it is already working. Resolves when the child settles. */
  send(text: string): Promise<void> {
    if (this.summary.status === "running" && this.session.isStreaming) {
      void this.session.steer(text);
      return this.done;
    }
    this.summary.status = "running";
    this.aborted = false;
    this.summary.startedAt = Date.now();
    this.summary.endedAt = undefined;
    this.summary.output = undefined;
    this.summary.error = undefined;
    this.done = this.session
      .prompt(text)
      .catch((error: unknown) => {
        this.summary.error = error instanceof Error ? error.message : String(error);
      })
      .then(() => this.finish());
    this.changed();
    return this.done;
  }

  async abort() {
    if (this.summary.status !== "running") return;
    this.aborted = true;
    await this.session.abort();
  }

  /**
   * AgentSession.dispose() doesn't emit session_shutdown, so extensions the child
   * started (MCP servers, timers) would outlive it and keep pi from exiting.
   */
  async dispose() {
    this.listeners.clear();
    const runner = this.session.extensionRunner;
    if (runner.hasHandlers("session_shutdown")) {
      await Promise.race([
        runner.emit({ type: "session_shutdown", reason: "quit" }).catch(() => undefined),
        new Promise((resolve) => setTimeout(resolve, 3000).unref()),
      ]);
    }
    this.session.dispose();
  }

  onChange(listener: () => void) {
    this.listeners.add(listener);
    return () => this.listeners.delete(listener);
  }

  private finish() {
    const last = [...this.session.messages].reverse().find((message) => message.role === "assistant") as
      | AssistantMessage
      | undefined;
    const summary = this.summary;
    summary.output = this.session.getLastAssistantText() ?? "";
    if (this.aborted || last?.stopReason === "aborted") {
      summary.status = "cancelled";
      summary.error = undefined;
    } else if (summary.error || last?.stopReason === "error") {
      summary.status = "error";
      summary.error ??= last?.errorMessage ?? "unknown error";
    } else summary.status = "completed";
    summary.endedAt = Date.now();
    if (summary.worktree) {
      try {
        settleWorktree(summary.worktree);
      } catch (error) {
        summary.worktree.kept = true;
        summary.activity.push(`worktree cleanup failed: ${error instanceof Error ? error.message : error}`);
      }
    }
    this.streaming = undefined;
    this.changed();
  }

  private handle(event: AgentSessionEvent) {
    const summary = this.summary;
    switch (event.type) {
      case "message_update":
        if (event.message.role === "assistant") this.streaming = event.message as AssistantMessage;
        break;
      case "message_end":
        this.streaming = undefined;
        if (event.message.role === "assistant") {
          const usage = (event.message as AssistantMessage).usage;
          if (usage) {
            summary.tokens.input += usage.input + usage.cacheRead;
            summary.tokens.output += usage.output;
            summary.cost += usage.cost?.total ?? 0;
          }
        }
        break;
      case "tool_execution_start":
        summary.toolCalls++;
        summary.activity.push(summarizeArgs(event.toolName, event.args));
        if (summary.activity.length > 8) summary.activity.shift();
        break;
      default:
        return;
    }
    this.changed();
  }

  private changed() {
    for (const listener of this.listeners) listener();
  }
}

/** The text the parent model receives, in the same shape opencode uses. */
export function resultText(summary: RunSummary): string {
  const limit = 50_000;
  let body =
    summary.status === "completed"
      ? summary.output || "Subagent completed without a text response."
      : summary.status === "error"
        ? `Subagent failed: ${summary.error}`
        : "Subagent was cancelled.";
  if (body.length > limit) {
    body = `${body.slice(0, limit)}\n\n[Output truncated. The full transcript is in ${summary.sessionFile ?? "the subagent session"}.]`;
  }
  const worktree = summary.worktree;
  if (worktree?.kept) {
    body += `\n\nThe subagent's changes are in the git worktree ${worktree.path} on branch ${worktree.branch}, based on ${worktree.base.slice(0, 12)}${worktree.dirty ? ", with uncommitted changes" : ""}. Review or merge them, then remove the worktree with \`git worktree remove ${worktree.path}\`.`;
  }
  return `<subagent sessionID="${summary.sessionID}" agent="${summary.agent}" state="${summary.status}">\n${body}\n</subagent>`;
}
