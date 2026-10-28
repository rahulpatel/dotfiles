#!/usr/bin/env bash
# Install pstack (https://github.com/cursor/plugins/tree/main/pstack) for pi and
# opencode. Fetches cursor/plugins at $PSTACK_REF, points every skill at the
# pi/opencode adapter (harness.md), writes the result to ~/.local/share/pstack,
# and adds the pstack subagents to pi and opencode.
set -euo pipefail

: "${PSTACK_REF:?set PSTACK_REF to a cursor/plugins commit}"
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
dest="$HOME/.local/share/pstack"
agents_dir="$HOME/.config/opencode/agents"
stamp="$PSTACK_REF $(cat "${BASH_SOURCE[0]}" "$here/harness.md" | shasum | cut -d' ' -f1)"

if [ "$(cat "$dest/.stamp" 2>/dev/null)" = "$stamp" ] && [ -f "$agents_dir/poteto-agent.md" ] && [ -f "$HOME/.pi/agent/agents/poteto-agent.md" ]; then
  echo "pstack is up to date at $PSTACK_REF"
  exit 0
fi

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

git init --quiet "$work/src"
git -C "$work/src" remote add origin https://github.com/cursor/plugins.git
team_skills=(deslop control-cli control-ui)
git -C "$work/src" sparse-checkout set pstack "${team_skills[@]/#/cursor-team-kit/skills/}"
git -C "$work/src" fetch --quiet --depth 1 --filter=blob:none origin "$PSTACK_REF"
git -C "$work/src" checkout --quiet FETCH_HEAD

src="$work/src/pstack"
out="$work/pstack"
mkdir -p "$out"
# Everything the plugin ships, so an update never leaves a new skill or optional
# pack behind. That includes skills/, agents/, docs/, automations/benny/, assets/,
# and .cursor-plugin/. Cursor-only pieces stay dormant (see harness.md).
cp -R "$src/." "$out/"
# Extra skills from the sibling cursor-team-kit plugin.
for skill in "${team_skills[@]}"; do
  cp -R "$work/src/cursor-team-kit/skills/$skill" "$out/skills/"
done
cp "$here/harness.md" "$out/docs/harness/pi-opencode.md"

line='In pi or opencode, read [the pi and opencode adapter](../../docs/harness/pi-opencode.md) once per session before you follow this skill. It maps the Cursor names in pstack skills to pi and opencode.'
# Like upstream's Claude Code tree, only skills with an H1 get the line. The
# others are one-paragraph prompts that use no Cursor names.
for skill in "$out"/skills/*/SKILL.md; do
  LINE="$line" perl -0pi -e 's/^(# .*)\n+/$1\n\n$ENV{LINE}\n\n/m' "$skill"
done

mkdir -p "$(dirname "$dest")"
rm -rf "$dest"
mv "$out" "$dest"

# Subagents: opencode and the pi subagent extension (home/.pi/agent/extensions/subagent)
# read the same Markdown agent format. pi ignores `mode`. Neither file pins a model,
# so pstack picks one per call.
pi_agents_dir="$HOME/.pi/agent/agents"
mkdir -p "$agents_dir" "$pi_agents_dir"
for agent in poteto-agent comment-sicko; do
  upstream="$dest/agents/$agent.md"
  description="$(grep -m1 '^description:' "$upstream")"
  preamble="pstack is installed at $dest. Read $dest/docs/harness/pi-opencode.md before you follow a pstack skill. The poteto-mode skill is $dest/skills/poteto-mode/SKILL.md."
  body="$(awk 'n >= 2 { print } /^---$/ { n++ }' "$upstream")"
  printf -- '---\n%s\nmode: subagent\n---\n\n%s\n%s\n' "$description" "$preamble" "$body" >"$agents_dir/$agent.md"
  cp "$agents_dir/$agent.md" "$pi_agents_dir/$agent.md"
done

echo "$stamp" >"$dest/.stamp"
echo "pstack installed at $PSTACK_REF ($(find "$dest/skills" -name SKILL.md | wc -l | tr -d ' ') skills)"
