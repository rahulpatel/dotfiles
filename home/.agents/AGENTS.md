- Be concise; sacrifice grammar if needed.
- Don't use jargon and speak coherently. State it more simply, like one human talking to another.

## Vendored repositories

Projects can contain external source repositories under `repos/`.

- Use a relevant vendored repository as read-only reference material.
- Prefer its source, tests, and examples to guesses or fragmented web results.
- Do not edit or import from `repos/` unless the user explicitly asks.
- `repos/` is globally ignored. Use explicit paths or `rg --no-ignore repos/` when searching it.
