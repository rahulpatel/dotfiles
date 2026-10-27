# pstack in pi and opencode

pstack skills use Cursor names. In pi or opencode, read this file once per session, then map each Cursor name in a skill with the tables below. `<pstack>` means `~/.local/share/pstack`, the folder that holds `skills/`, `agents/`, and `docs/`. If a Cursor field has no row, drop it and say so. Never pass a field or value that the tool schema rejects.

Find your harness first. opencode has a `skill` tool. pi has none and lists skills as `/skill:<name>`.

## Tools

| Cursor | opencode | pi |
| --- | --- | --- |
| `Task` | The `subagent` tool. See Subagents. | The `subagent` tool. See Subagents. |
| `AskQuestion` | The `question` tool. | Ask in plain text with numbered options, then stop and wait for the reply. |
| Open a todolist | Use a todo tool if the session has one. Otherwise keep the list in your reply and update it at each phase. | Keep the list in your reply and update it at each phase. |
| Run another pstack skill (`/name` or "the **name** skill") | The `skill` tool with ID `<name>`. When you tell the user to type it, write `@<name>`. | `read` `<pstack>/skills/<name>/SKILL.md` and follow it. When you tell the user to type it, write `/skill:<name>`. |
| `Grep`, `Glob`, `Read`, `Shell` | `grep`, `glob`, `read`, `shell`. | `bash` with `rg` and `fd`, and `read`. |
| `/loop` | No loop command. To wait for an event, run a blocking command, such as the PR watcher, in the shell and act on its output in the same turn. A timed tick, such as `/loop 1h`, is a skip. See Cursor-only features. | Same as opencode. |

## Subagents

Both harnesses have a `subagent` tool with the same core inputs: `agent`, `description` (three to five words), `prompt` (the brief), `model`, `sessionID`, and `background`. Each subagent runs in a child session and cannot spawn subagents. pi's tool, from `~/.pi/agent/extensions/subagent`, also takes `thinking`, `readonly`, `worktree`, and `cwd`, and the user watches its subagents with `/subagents`.

| Cursor | opencode `subagent` input | pi `subagent` input |
| --- | --- | --- |
| `subagent_type: generalPurpose` | `agent: "general"`. | `agent: "general"`. |
| `subagent_type: "poteto-agent"` | `agent: "poteto-agent"`. | `agent: "poteto-agent"`. |
| `subagent_type: "comment-sicko"` | `agent: "comment-sicko"`. | `agent: "comment-sicko"`. |
| `readonly: true` | `agent: "explore"`. When the step also names `poteto-agent`, keep `poteto-agent`, write "do not edit files" in the brief, and check `git status` afterward. | `readonly: true`, with any agent. pi blocks edits and sandboxes `bash` against file writes. |
| `readonly: false` | `general` or the named agent. | Omit `readonly`. |
| `model: <slug>` | See Models. `model: "<provider>/<model>#<effort>"`. | See Models. `model: "<provider>/<model>"` and `thinking: "<effort>"`. |
| `run_in_background: true` | `background: true`. You are notified when it finishes. | Same as opencode. |
| A parallel panel | One `subagent` call per entry in the same message, each with its own `model`. They run in parallel. | Same as opencode, with `thinking` per entry. |
| `resume` | `sessionID` of the earlier subagent, with the same `agent`. | Same as opencode. |
| `environment: "cloud"` | Make a git worktree with `git worktree add`, and name its path and branch in the brief. | `worktree: true`. The result names the worktree and branch if the worker changed anything. |
| `environment: "local"` | Omit. | Omit. |
| `cloud_base_branch: <b>` | Tell the worker to check out `<b>` first. | Same as opencode. |
| `file_attachments` | List the paths in the brief. | Same as opencode. |
| `is_background` | Omit. | Omit. |

## Models

| Cursor | pi and opencode |
| --- | --- |
| The `pstack-models.mdc` rule, `~/.cursor/rules/pstack-models.mdc` | `~/.agents/pstack-models.md`. Read it once per session, before the first subagent. If the file or the role's line is missing, the role uses the session model. Say so once, and tell the user to run `setup-pstack`. Never fall back to a Cursor slug. |
| A role value `<provider>/<model> <effort>`, such as `github-copilot/claude-opus-5.5 xhigh` | opencode: `model: "github-copilot/claude-opus-5.5#xhigh"`. pi: `model: "github-copilot/claude-opus-5.5"` and `thinking: "xhigh"`. |
| `inherit-parent` or `auto` | Omit the model, so the role runs on the session model. |
| A Cursor slug in a skill, such as `claude-opus-5-5-xhigh` or `grok-4.7-xhigh-fast` | The value of the role that the skill names, from the rule file. If the rule has no such role, use the session model and say so. |
| A model that the harness does not have | Use the session model and say so in one line. pi and opencode can have different providers, so a rule value can work in one and not the other. |

## setup-pstack

`setup-pstack` writes `~/.agents/pstack-models.md`, which pi and opencode share. Follow its steps with these changes:

- Detect. In opencode, run `opencode models` in the shell. If the `models` tool is available, its `variants` are the efforts for each model. In pi, run `pi --list-models`. A model with `thinking: yes` accepts `low`, `medium`, `high`, `xhigh`, and `max`. pi lowers an effort that the model does not support. Write a real model as `<provider>/<model> <effort>`, such as `github-copilot/claude-opus-5.5 xhigh`. The effort is the last token, so the budget step works as written. Prefer models that both harnesses list. Ask the user before you run the other harness's command.
- Defaults. Map each default slug to a detected model of the same family: `claude-opus-5-5-xhigh` is the newest Claude Opus at `xhigh`, and `grok-4.7-xhigh-fast` is the newest Grok at `xhigh`. Drop `fast`. If no model of that family is detected, use `inherit-parent`.
- Write. Write `~/.agents/pstack-models.md` with no frontmatter, then the comment lines, the `# budget` line, and one line per role from step 5. Overwrite the whole file. Never put the role lines in `AGENTS.md`.
- Steps 7 and 8. Project skills go in `.agents/skills/`, because pi and opencode both read that folder.

## Paths

| Cursor | pi and opencode |
| --- | --- |
| `.cursor/skills/`, `~/.cursor/skills/` | `.agents/skills/`, `~/.agents/skills/`. Both harnesses read them. |
| `~/.cursor/plugins/`, `.cursor-plugin/plugin.json` | `<pstack>`, `<pstack>/plugin.json`. Only one copy is installed. |
| `.cursor/rules/*.mdc`, always-applied rules | `AGENTS.md`. The model rule is the exception. See Models. |
| `https://github.com/cursor/plugins/blob/main/pstack/<path>` | `<pstack>/<path>` when that file exists. Read the local copy and do not fetch it. Give the user the URL when they need a link. |
| The agent's store (path in the system prompt) | `~/.local/state/pstack/<repo-slug>/`. Make it when you need it. |
| Transcripts in `~/.cursor/projects/<slug>/agent-transcripts/` | pi: `~/.pi/agent/sessions/<slug>/*.jsonl`. The slug is the workspace path with each `/` changed to `-`, wrapped in `--`, so `/Users/you/proj` is `--Users-you-proj--`. The newest file is the current session. opencode: `opencode session list` in the workspace, then `opencode session export <id>` for each session. Read only this workspace's sessions. |

## Cursor-only features

pi and opencode have no Cursor Automations, Bugbot, Cursor cloud agents, custom modes, `/loop` timers, or built-in PR tool. When a step needs one, put one line in your reply, `Skipped in <pi|opencode>: <step>. <reason>.`, then go on to the next step. Do not stop, ask, or retry. When a later step needs what the skipped step made, such as a URL or a key, leave a placeholder and name it in the line.

`<pstack>/automations/benny/` ships with pstack but is dormant: it is a Cursor Automations pack, so never set it up, install its skills, or call it from a pi or opencode session.

| Cursor | pi and opencode |
| --- | --- |
| Cursor Automations: routines, `update_state` routine calls, `api2.cursor.sh/automations` webhooks, routine wakes, and `SendToUser` secret requests | Skip with the line. |
| Bugbot | Bugbot comments on a GitHub PR are ordinary review threads, so triage them with the forge command that the step gives. Skip a step that starts, waits for, or configures Bugbot when the PR has no Bugbot check or comment. |
| Cursor cloud agents | `environment: "cloud"` maps to a worktree, as in the subagent sections. Skip a step that needs the cloud agent itself, such as its dashboard status or its own machine. |
| Custom modes (Option+Enter) | Skip. The user starts each task with the skill again. |
| `/loop` with a timer | Skip with the line, and tell the user to prompt again when they want the next tick. |
| A built-in PR tool | Use the forge command that the step gives, such as `gh pr create`. That is not a skip, so write no line. |
