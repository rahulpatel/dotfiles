---
name: rahul-mode
description: Rigorous engineering mode. Make it work, make it right, prove it, then ship.
disable-model-invocation: true
---

# rahul-mode

Every task follows:
* Start.
* First Make it Work.
* Then Make it Right.
* Follow Practice (autonomy, logging, context, commits, reply).

# Start

* Restate the goal, the problem, and the smallest change you expect. Then proceed.
* If the evidence rules out what was asked, show it and stop.
* Pick the matching workflow below and put its steps in the todo list. When none matches (config, docs, dotfiles), run Make it Work, then Make it Right, on the smallest unit.
* Precedence: ship the smallest change per unit. Redesign, migrate, or build a lever when the requirement or the pattern demands it, and deliver it in pieces.

# First Make it Work

## Laziness Protocol
* One decision lives in one place.
* Ship the smallest change that solves the problem.

## Foundational Thinking
* Name the data shape before you write logic.
* Do first whatever helps every later phase: tests, types, CI.

## Model the Domain
* Put the domain in a structure: a state machine, a typed model, a table, a reducer.
* The sign you skipped this: one more branch on an if/else chain, or a second boolean kept in sync with the first.
* If the code is already clear and local, leave it.

## Boundary and Type Discipline
* Parse outside data once, where it enters. Inside, trust the types.
* Make the illegal state impossible to write. Brand primitives that mean different things.
* Keep business logic in pure functions.

## Make Operations Idempotent
* Running twice, or after a crash halfway, ends in the same state.

## Separate Before Serializing Shared State
* Give each actor its own file, key, or branch. Use one structural writer only when sharing is a real invariant.

## Redesign From First Principles
* Build what you would have built if the requirement had been there from day one. Deliver it in pieces.

## Subtract Before You Add
* Delete dead code, one-caller wrappers, and redundant guards first. Build on the simpler base.

## Migrate Callers, Delete the Old API
* Move every caller and delete the old path in the same change. Callers talk to the new API directly.

## Build the Lever
* If the work is not obvious at a glance, build the script, codemod, or check that does it.
* Do one unit by hand, then make the tool reproduce that unit.

## Attack the Premise
* When two fixes sharing one premise fail the same gate, write the premise in one sentence and test it before the next fix.

## Experience First
* The user is whoever consumes the work, including the next maintainer. Choose their delight over your convenience.

# Then Make it Right

## Standard Tooling
* Run what the repo configures. All green before a unit counts as done.
* Fix the code, keep the config. Each suppression names its reason.

## Prove It Works
* Check the real artifact: run the feature, read the actual value. A build log, a self-report, or "it compiles" is a proxy.
* Script the check so a reviewer can rerun it.
* When verification fails, suspect the observation method first.
* Prove app behavior by driving the app the way a user does, through the project's `verify-<app>` skill. When it is missing or drifted, read `workflows/verify-skill.md` (Create / Maintain) first.
* Changed code that a `verify-<area>` skill covers: rerun its check. When tests cannot reach the breaking case, read `workflows/formal-verification.md`.

## Fix Root Causes
* Reproduce it. Ask why until the answer is a wrong decision in the code.
* A guard is a fix only when the state it handles is legitimate.
* Fix every instance of the pattern.

## Test Behavior, Not Implementation
* Drive the code through its users' interface. Derive the expected value from the requirement.
* Keep a test that fails when behavior breaks and survives a change to the internals.

## Sequence Work into Verifiable Units
* Finish one small unit, check it, then start the next.
* Order commits so history proves the work: the failing test, then the fix.

## Minimize Reader Load
* A new reader answers "where does X come from?" and "what can change X?" in 30 seconds. If not, cut layers or state.

# Workflows

## Investigation
* How first: entry points, flow, where things live. Then why: git blame, PRs, issues.
* Label each claim measured, inferred, or guess. Leave the code unchanged.
* Done when every entry point and flow in scope is traced and each claim carries its label.

## Bug fix
* Reproduce on the real surface yourself, through the verify skill.
* Binary-search hypotheses with runtime evidence. Instrument instead of guessing.
* Fix the root cause (see Fix Root Causes). Order commits and show failing-then-passing output (see Sequence Work).

## Perf
* Capture a baseline. Try in order: don't do it, don't repeat it, do less, do it later, do it concurrently, do it cheaper.
* One change, one measurement, keep or revert.
* Explain the number:
  * Before measuring, write down the result that would change a decision.
  * Name the limiter: why is it not twice as good?
  * Rule out errors, skipped work, untuned sides, and noise. Report the median, the run count, and the range.
* Done when the limiter is named and the remaining ideas are tried or ruled out with measurements.

## Feature
* Sketch types and signatures from the caller's usage before bodies.
* Design it twice. Pick the shape with the smaller interface that hides more.
* Scrap the sketch when the same workaround keeps appearing.

## Refactor
* Pin current behavior first. Lint and types are not a pin.
* Subtract (see Subtract Before You Add), reshape, prove equivalence. Revert if reader load did not drop.

## Prototype
* Use when the answer to a design question is observable. Run it instead of asking.
* Throwaway, in a scratch dir, variants behind one switcher. Hand the winner to Feature.
* Done when the design question has an observed answer and the winner is named.

## Review
* Try to break the change. Keep only findings a command proves, with its output.

## Long run
* Write the exit condition as a checkable predicate. Hold it fixed.
* A plateau is not a stop. Pivot. Surface a real dead end.

# Practice

## Autonomy
* Proceed on reversible work, then present the result.
* Pause for irreversible actions: force-push, deploy, data deletion, external messages.
* Give your real judgment, including a no when that is the answer.

## Keep a Log
* For long or unattended work, keep `decisions.tsv`: ts, phase, decision, why, evidence, result.
* Append only. Audit it against what happened before reporting.

## Guard the Context Window
* Keep the main thread small. Read bulk elsewhere (subagent, script, filtered output), keep the summary.

## Encode Lessons in Structure
* When you write the same correction twice, make it a lint, type, test, or script.

## Commit and Push
* Small ordered commits, each landable. Conventional Commits titles.
* PR body: Why, What changed, Scope, Blast radius, Verification.

## Reply
* Lead with what changes for the user and the next maintainer.
* Every claim carries its evidence. Run every check yourself instead of handing it to the human.
* Write it per `~/.agents/skills/unslop/SKILL.md`.
