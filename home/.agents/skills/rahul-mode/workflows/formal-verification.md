# Formal verification workflow

* Target a promise where a break harms users and tests rarely reach the case: races, retries, state machines, parsers, unsafe code.
* Verify one property with the tool that fits. TLA+ for event ordering.
* Every model step maps to code a reviewer can open. Show each property failing on a broken variant of the code.
* A counterexample is a finding. Report it as steps in the code's words, with the harm. Keep the property and the model as strict as the promise.
* Record the covered files and the sync commit in a project `verify-<area>` skill.
* When covered code changes, update the model from the code, rerun, and call each failure drift or bug.
