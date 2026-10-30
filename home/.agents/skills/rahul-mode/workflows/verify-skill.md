# Verify skill workflows

## Create a verify skill
* Write `.agents/skills/verify-<app>/SKILL.md` from the repo, not from guesses:
  * Launch: the exact command to a usable state from empty data, and teardown.
  * Doctor: one read-only check that the instance is worth driving.
  * Drive: real selectors and commands, stable handles over coordinates.
  * Evidence: the real user path, the action and the resulting state, side effects. Evidence survives cleanup.
  * Cleanup: kill what you started, by the PID you recorded.
  * Feature map: `features/<feature>.md` per user-facing feature. How to reach it, how to drive it, the end state that proves it.
* Done when the skill has run end to end once: launch, doctor, drive one feature, capture evidence, clean up.

## Maintain a verify skill
* Drive every feature in the map live.
* Fix the map for doc drift and the harness for harness gaps. Report product regressions separately.
* Done when every feature in the map has been driven live and each failure is labeled drift, harness gap, or product regression.
