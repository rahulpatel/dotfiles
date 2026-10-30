/**
 * subagent: delegate tasks to pi sessions that run hidden in Rex (detached blocks).
 *
 * Coordinator: `subagent` tool (task, role, name, model, thinking) shows a live card inline;
 *   /attach and /detach show or hide an agent in a split; the footer counts running agents;
 *   a stuck agent asks via ask_coordinator and the coordinator answers with subagent_reply.
 * Subagent (PI_SUBAGENT_DIR set): reports activity and its result through files (protocol.ts).
 */
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { registerChild } from "./child.ts";
import { registerParent } from "./parent.ts";
import { ENV_DIR } from "./protocol.ts";

export default function (pi: ExtensionAPI) {
  const dir = process.env[ENV_DIR];
  if (dir) registerChild(pi, dir);
  else registerParent(pi);
}
