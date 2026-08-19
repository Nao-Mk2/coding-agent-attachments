# Risk rules

Use these rules to classify PR risk and decide review focus.

## High risk

Classify as `高` if any of these are true:

- authentication or authorization changes
- personal data, sensitive data, payment, or important business data changes
- DB schema migration, data migration, bulk update, or delete operation
- external integration, webhook, event, queue, or asynchronous processing changes
- retry, idempotency, transaction, or recovery behavior changes
- failure may be hard to roll back
- tests are missing while the impact range is broad
- important context is missing and the changed area is security, data, permission, migration, or external integration
- AI evaluation has low confidence in an important area

Human review should focus on intent, permission model, data impact, failure behavior, rollback, and acceptance criteria.

## Medium risk

Classify as `中` if any of these are true and no high-risk condition applies:

- multiple modules or layers changed
- API or UI behavior changed
- existing branching logic changed
- business rule changed
- dependency changed
- test coverage exists but edge cases are weak
- maintainability, compatibility, or reliability may be affected

Human review should focus on changed behavior, edge cases, test adequacy, and consistency with existing design.

## Low risk

Classify as `低` only if all of these are true:

- impact range is narrow
- little or no business judgment is needed
- no data, permission, external integration, migration, or irreversible side effect is involved
- automated tests or static checks cover the main risk
- no important low-confidence area remains

Human review can focus on whether the change matches the stated intent.

## Failure case prompts

When identifying likely failures, check these cases first:

- empty, null, invalid, duplicated, or stale input
- insufficient permission
- external API failure
- timeout
- retry after partial success
- concurrent execution
- re-run of the same operation
- old production data that does not match new assumptions
- missing configuration or environment difference
- logging sensitive data
- client using an old API or schema

## Test recommendation rules

For each additional test, include:

- test name
- what it verifies
- priority: `高`, `中`, or `低`
- automation: `できる`, `難しい`, or `人間確認`

Prefer tests that reduce review uncertainty. Do not recommend broad generic tests when a specific test can be named.
