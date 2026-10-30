/** Live subagent state shared by the tool and the panel. One entry per spawned subagent. */
import type { ThinkingLevel } from "@earendil-works/pi-agent-core";

export type Status = "running" | "done" | "error" | "cancelled";

export interface Subagent {
  id: number;
  name: string;
  task: string;
  model: string;
  thinking: ThinkingLevel;
  status: Status;
  startedAt: number;
  endedAt?: number;
  /** Recent tool calls and steering messages, oldest first. */
  log: string[];
  /** Assistant text of the turn in progress. */
  text: string;
  steer(message: string): Promise<void>;
  cancel(): void;
}

const agents = new Map<number, Subagent>();
const listeners = new Set<() => void>();
let nextId = 1;

export const nextAgentId = () => nextId++;
export const allAgents = () => [...agents.values()];
export const runningAgents = () => allAgents().filter((a) => a.status === "running");

export function track(agent: Subagent): void {
  agents.set(agent.id, agent);
  changed();
}

export function changed(): void {
  for (const l of listeners) l();
}

export function onChange(fn: () => void): () => void {
  listeners.add(fn);
  return () => listeners.delete(fn);
}

/** Finished agents stay in the registry for the whole session; the panel can hide them. */
export function finish(agent: Subagent, status: Exclude<Status, "running">): void {
  agent.status = status;
  agent.endedAt = Date.now();
  changed();
}

export function pushLog(agent: Subagent, line: string, max = 200): void {
  agent.log.push(line);
  if (agent.log.length > max) agent.log.splice(0, agent.log.length - max);
}
