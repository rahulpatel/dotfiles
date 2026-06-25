# Logging

These standards are adapted from ["Logging sucks. And here's how to make it better."](https://loggingsucks.com/) by Boris Tane, and shaped to fit the local `coding-standards` package.

## Purpose

Logs are an incident-debugging interface. Optimize them for querying, correlation, and safe human diagnosis, not for narrating code execution.

Good logs should answer these questions quickly:

- Who or what was affected?
- What operation or state transition was happening?
- Which request, job, workflow, or external call is involved?
- What failed, degraded, retried, or completed?
- What safe context distinguishes this case from nearby cases?

## Adoption Rule

Inspect the existing observability stack before changing logs: logger API, field names, tracing IDs, metrics, error reporter, redaction tools, sampling, and runtime conventions.

Prefer local conventions unless they conflict with safety, redaction, correlation, or incident-debuggability. Do not introduce a new logger, event taxonomy, schema library, tracing system, or broad field-name migration for a local logging change unless the user asks.

## Where Logging Belongs

Logging is usually an imperative-shell concern. Core/domain code should generally return typed values, tagged Expected Failures, or domain events rather than depend directly on logger/time/random/trace APIs.

Log at owned seams and orchestration boundaries:

- HTTP/RPC/CLI request entry and exit, when not already covered by infrastructure.
- Background job, queue consumer, workflow step, and scheduled task start/completion/failure.
- External service calls with operation, dependency, duration, status, and retry context.
- Important domain state transitions such as `order_paid` or `invoice_voided`.
- Retry attempts, fallbacks, circuit-breaker changes, redelivery, and idempotency conflicts.
- Authentication, authorization, and security-relevant decisions with safe context.

Avoid duplicate logs at every layer. A lower module should usually return the Expected Failure with safe structured context; the boundary that owns user impact, retry policy, or incident response logs it once.

## Structured Events

Prefer a Structured Event over interpolated strings. Each event should have a stable event name and queryable fields.

```json
{
  "level": "warn",
  "event": "billing.payment_failed",
  "request_id": "req_123",
  "account_id": "acct_456",
  "payment_id": "pay_789",
  "failure_tag": "InsufficientFunds",
  "amount_cents": 9999,
  "duration_ms": 245
}
```

Do not make prose the only carrier of meaning. A message can help humans, but fields should carry the values needed for filtering, grouping, and alerting.

## Required Context

Use fields already supplied by the runtime/logger instead of duplicating them manually. A complete emitted log event should include or inherit:

- `timestamp` with timezone.
- `level`: `debug`, `info`, `warn`, or `error`, matching local conventions.
- `event`: stable machine-readable event name.
- `service` or application name.
- `environment` or deployment target.
- `request_id`, `trace_id`, `span_id`, `job_id`, `workflow_id`, or equivalent correlation ID when available.

Add Safe Telemetry Fields when they materially improve diagnosis:

- `user_id`, `account_id`, `org_id`, or tenant identifier.
- `order_id`, `payment_id`, `invoice_id`, `transaction_id`, or resource identifier.
- `dependency`, `operation`, `attempt`, `status_code`, `duration_ms`, or retry metadata.
- Stable error tags, failure kinds, or Safe Error Summary fields.

High-cardinality fields are valuable in logs when safe and supported by the log backend. Do not add unsafe PII or fields that explode cost/cardinality without operational value.

## Correlation Propagation

Preserve Correlation Context across seams:

- Inherit upstream IDs in HTTP headers, RPC metadata, queue messages, workflow payloads, and background jobs.
- Restore relevant context before logging async work that continues outside the original request.
- Prefer middleware/interceptors/runtime context only when it is reliable for the runtime seam.
- Pass typed metadata explicitly across runtime hops where ambient context does not propagate.

If a task adds a new adapter, queue producer, workflow step, or external call wrapper, check whether it preserves established observability context.

## Levels

Use levels for operational meaning, not aesthetics:

- `debug`: verbose local or deep diagnostic detail, usually disabled or sampled in production.
- `info`: normal but meaningful lifecycle events, user-visible actions, job completions, deploys, and audit-relevant decisions.
- `warn`: unexpected or degraded behavior that the system handled, such as retries, fallback paths, stale data, partial failure, or rate limiting.
- `error`: failed operation likely requiring human attention, alerting, or incident review.

Do not log normal Expected Failures as errors merely because they are negative outcomes. A wrong password, validation failure, not-found lookup, or business-rule rejection is usually `info` or `warn` only when the product/security context makes it operationally meaningful.

## Error Logging

Expected Failures should have stable tags, useful messages, safe telemetry fields, and optional `cause: unknown`. Log the tag and safe fields; do not stringify arbitrary error objects as telemetry.

When catching exception-style dependencies:

- Catch `unknown`.
- Recognize cancellation before ordinary failure wrapping.
- Classify the cause into the local typed failure or framework contract.
- Preserve useful cause data for debugging where safe.
- Log a Safe Error Summary, not secrets or arbitrary serialized objects.

Unrecoverable Defects can be logged or reported as defects, but still need redaction and correlation. Do not hide a violated invariant behind a vague low-level log message.

## Redaction

Never put secrets in logs, traces, metrics, snapshots, panic summaries, or error-reporting metadata.

Do not log:

- Passwords, tokens, API keys, session IDs, cookies, private keys, auth headers, or raw credentials.
- Payment card data, sensitive financial data, medical data, or regulated personal data.
- Raw request/response bodies unless the contract is explicitly safe and bounded.
- Arbitrary `JSON.stringify` of user records, dependency responses, errors, env vars, headers, or config.

Wrap sensitive values in a Redacted Value at the seam when the codebase has that pattern. Unwrap only where the raw value is needed.

## Event Names And Fields

Prefer established project naming. For new conventions, use stable names:

- Field names: `snake_case` unless the project has a different convention.
- Events: past-tense facts such as `payment_completed`, `job_failed`, or `invoice_created`.
- Domain prefix when helpful: `auth.login_failed`, `billing.invoice_created`.
- Units in field names where ambiguous: `duration_ms`, `amount_cents`, `retry_after_seconds`.
- Tags over prose for grouping: `failure_tag`, `dependency`, `operation`, `reason_code`.

Avoid renaming existing telemetry fields casually. Dashboards, alerts, notebooks, and incident runbooks may depend on them.

## Performance And Volume

Logging has runtime and storage cost. Keep volume proportional to operational value.

- Avoid logs inside tight loops, hot paths, and high-frequency polling unless sampled or aggregated.
- Sample high-volume debug logs in production.
- Prefer counters/metrics for high-rate aggregate facts; use logs for diagnostic exemplars and context.
- Ensure expensive log fields are lazy or guarded when the logger supports disabled levels.
- Keep payloads bounded; do not emit unbounded arrays, bodies, stack chains, or dependency responses.

## Review Lens

For logging changes, look for concrete consequences:

- Missing correlation that prevents tracing a request, job, workflow, or dependency call.
- Secrets, PII, credentials, raw bodies, or unsafe error summaries reaching telemetry.
- Expected Failures logged as defects or thrown errors logged repeatedly across layers.
- New adapters or failure translations that bypass established tracing, logging, metrics, or error reporting.
- String-only logs that cannot be queried by event, resource, tenant, operation, or failure tag.
- New field names that split existing dashboards/queries without migration intent.
- High-volume logs on hot paths without sampling, level guard, or clear incident value.

Only report logging issues when the changed code introduces or worsens debuggability, safety, cost, or operational-risk consequences. Do not require broad observability migrations for unrelated local edits.

## Incident Feedback Loop

After an incident or debugging session, add the smallest logs, fields, metrics, or traces that would have shortened diagnosis. Prefer one precise event or safe field at the right seam over broad extra narration.
