import { existsSync, readdirSync, readFileSync } from "node:fs";
import { join } from "node:path";
import { getAgentDir, parseFrontmatter } from "@earendil-works/pi-coding-agent";

export const THINKING_LEVELS = ["off", "minimal", "low", "medium", "high", "xhigh", "max"] as const;
export type Thinking = (typeof THINKING_LEVELS)[number];

export interface AgentConfig {
  name: string;
  description: string;
  /** Appended to pi's system prompt, or replaces it when `promptMode` is "replace". */
  prompt: string;
  promptMode: "append" | "replace";
  model?: string;
  thinking?: Thinking;
  readonly: boolean;
  source: string;
}

const BUILTIN: AgentConfig[] = [
  {
    name: "general",
    description: "General-purpose agent for research and multi-step tasks, including edits.",
    prompt: "",
    promptMode: "append",
    readonly: false,
    source: "builtin",
  },
  {
    name: "explore",
    description:
      "Read-only agent for exploring codebases: find files, search code, and answer questions about how things work.",
    prompt:
      "You explore code and report what you find. You cannot change files. Search broadly, read what matters, and cite paths with line numbers.",
    promptMode: "append",
    readonly: true,
    source: "builtin",
  },
];

function readDir(dir: string, source: string): AgentConfig[] {
  if (!existsSync(dir)) return [];
  const agents: AgentConfig[] = [];
  for (const file of readdirSync(dir)) {
    if (!file.endsWith(".md")) continue;
    try {
      const { frontmatter, body } = parseFrontmatter<Record<string, unknown>>(readFileSync(join(dir, file), "utf8"));
      const thinking = String(frontmatter.thinking ?? "");
      agents.push({
        name: String(frontmatter.name ?? file.slice(0, -3)),
        description: String(frontmatter.description ?? ""),
        prompt: body.trim(),
        promptMode: frontmatter.prompt_mode === "replace" ? "replace" : "append",
        model: typeof frontmatter.model === "string" ? frontmatter.model : undefined,
        thinking: (THINKING_LEVELS as readonly string[]).includes(thinking) ? (thinking as Thinking) : undefined,
        readonly: frontmatter.readonly === true,
        source,
      });
    } catch {
      // A malformed agent file shouldn't take down the tool.
    }
  }
  return agents;
}

/** Built-ins, then ~/.pi/agent/agents, then the project's .pi/agents. Later files win. */
export function discoverAgents(cwd: string, projectTrusted: boolean): AgentConfig[] {
  const byName = new Map<string, AgentConfig>();
  const all = [
    ...BUILTIN,
    ...readDir(join(getAgentDir(), "agents"), "user"),
    ...(projectTrusted ? readDir(join(cwd, ".pi", "agents"), "project") : []),
  ];
  for (const agent of all) byName.set(agent.name, agent);
  return [...byName.values()].sort((a, b) => a.name.localeCompare(b.name));
}
