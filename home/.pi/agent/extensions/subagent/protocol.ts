/**
 * File protocol between a parent pi and a subagent pi, one directory per agent:
 *   activity.json  child → parent  recent tool calls / text, for the live card
 *   question.json  child → parent  {n, text}: the child is stuck and asks the coordinator
 *   answer.json    parent → child  {n, text}
 *   result.json    child → parent  {ok, text}: final message of the first finished run
 */
import { mkdir, readFile, rename, writeFile } from "node:fs/promises";
import { join } from "node:path";

export const ENV_DIR = "PI_SUBAGENT_DIR";
/** The coordinator's Rex block, so a subagent can hand focus back when it detaches itself. */
export const ENV_PARENT_BLOCK = "PI_SUBAGENT_PARENT_BLOCK";

export interface Activity { lines: string[] }
export interface Question { n: number; text: string }
export interface Answer { n: number; text: string }
export interface Result { ok: boolean; text: string }

export type FileName = "activity" | "question" | "answer" | "result";
export interface Shapes { activity: Activity; question: Question; answer: Answer; result: Result }

export const read = async <K extends FileName>(dir: string, name: K): Promise<Shapes[K] | undefined> => {
  try {
    return JSON.parse(await readFile(join(dir, `${name}.json`), "utf8")) as Shapes[K];
  } catch {
    return undefined; // missing, or caught mid-write
  }
};

let seq = 0;
/** Write atomically so a reader never sees half a file. Each write has its own temp file, so overlapping writes cannot collide. */
export const write = async <K extends FileName>(dir: string, name: K, value: Shapes[K]): Promise<void> => {
  await mkdir(dir, { recursive: true });
  const tmp = join(dir, `.${name}.${process.pid}.${++seq}.tmp`);
  await writeFile(tmp, JSON.stringify(value));
  await rename(tmp, join(dir, `${name}.json`));
};

export const sleep = (ms: number) => new Promise<void>((r) => setTimeout(r, ms));
