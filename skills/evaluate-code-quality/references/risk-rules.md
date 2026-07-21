# Risk rules

Risk is based on concrete findings, not on the selected characteristic, changed file count, or missing context. Confidence communicates evidence quality separately and never raises risk by itself.

## Finding types

### `confirmed_issue`

The available code establishes an executable failure path. A finding must identify the location, code evidence, failure condition, impact, and required action.

### `credible_risk`

The available code establishes a plausible executable failure path, but specification, environment, production-data, or call-path information is required to confirm the outcome.

### `missing_evidence`

No implementation defect is established, but an important guarantee lacks a test or required evidence. Missing tests alone must not be described as a code defect.

Do not report generic possibilities, minor style or naming issues, behavior absent from the diff, or duplicated findings with the same root cause.

## High risk

Classify as `高` only when a high-severity `confirmed_issue` concretely establishes at least one of:

- missing or bypassed authentication or authorization
- exposure of personal data, credentials, or secrets
- irreversible or broad deletion or data corruption
- incorrect money handling or critical state transition
- inability to recover from a migration failure
- inconsistency caused by duplicate execution or partial success
- a production failure that cannot be rolled back safely

Touching authentication, personal data, migration, external integration, asynchronous processing, transaction, or recovery code is routing evidence only. It is not sufficient for `高`.

## Medium risk

Classify as `中` when no high-risk condition applies and at least one of:

- a `confirmed_issue` has material but limited production impact
- a `credible_risk` has a concrete executable production failure path
- permission, data integrity, backward compatibility, transaction/retry behavior, or rollback lacks required verification

## Low risk

Classify as `低` when neither a high nor medium condition is established. A narrow change, broad change, or missing generic check does not determine this classification by itself.

## Confidence

- `高`: relevant code and context are available, and observed checks cover the main risk.
- `中`: findings are grounded, but some non-critical context or checks are unavailable.
- `低`: essential specification, call-path, production-data, or test evidence is unavailable for the selected characteristics.

Always provide one concise confidence reason. Never promote risk because confidence is low.

## Report limits

- Merge-blocking or merge-relevant findings: maximum 5
- Missing tests: maximum 3
- Human judgment points: maximum 3
- Verified checks: maximum 3
