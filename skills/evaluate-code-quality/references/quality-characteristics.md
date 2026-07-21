# Quality characteristics

Use this reference after the mandatory core evaluation to select zero to two affected software quality characteristics.

Do not check every item mechanically. Select only characteristics supported by concrete diff evidence. Rank candidates by potential harm, breadth, irreversibility, and uncertainty, then keep at most two. Do not select a characteristic merely to fill the limit.

The core evaluation already covers change intent, likely failures, test adequacy, human review focus, uncertainty, and overall risk. Avoid repeating those points in a specialist characteristic unless they are necessary to explain that characteristic's specific impact.

## 機能適合性

The PR affects expected functions, business rules, acceptance criteria, normal flows, edge cases, or error handling.

Common signals:

- business logic changed
- validation changed
- calculation or condition changed
- new feature or behavior added
- bug fix changes expected behavior

Confirmation examples:

- unit test for business logic
- acceptance test
- integration test
- specification review by product or domain owner

## 性能効率性

The PR may affect response time, processing time, memory use, database load, network traffic, or batch duration.

Common signals:

- query changed
- loop or bulk processing changed
- large data path changed
- cache behavior changed
- synchronous/asynchronous boundary changed

Confirmation examples:

- benchmark
- query plan check
- load test
- production-like measurement

## 互換性

The PR may affect compatibility with existing consumers, data, APIs, events, clients, environments, or external systems.

Common signals:

- API schema changed
- request or response format changed
- DB schema or migration changed
- event payload changed
- configuration format changed
- dependency version changed

Confirmation examples:

- contract test
- schema diff
- backward compatibility test
- migration dry run

## 相互作用性

The PR may affect user interaction, screen behavior, navigation, input/output, accessibility, error messages, or visible wording.

Common signals:

- UI changed
- form behavior changed
- user action flow changed
- displayed state or message changed
- accessibility attributes changed

Confirmation examples:

- end-to-end test
- visual check
- accessibility check
- product/design review

## 信頼性

The PR may affect failure handling, recovery, retry, timeout, idempotency, consistency, or resilience.

Common signals:

- exception handling changed
- retry or timeout behavior changed
- async job changed
- transaction boundary changed
- concurrent execution path changed
- error state handling changed

Confirmation examples:

- failure injection test
- retry/idempotency test
- timeout test
- rollback/recovery test

## セキュリティ

The PR may affect authentication, authorization, data protection, input validation, secrets, logging, dependencies, permissions, or external communication.

Common signals:

- auth/authz logic changed
- personal or sensitive data touched
- user input processing changed
- file upload/download changed
- token, secret, cookie, or session handling changed
- dependency or container image changed

Confirmation examples:

- permission test
- input validation test
- static application security test
- dependency scan
- secret scan
- manual threat review for high-risk changes

## 保守性

The PR may affect readability, complexity, cohesion, coupling, testability, dependency direction, or future modification cost.

Common signals:

- large conditional logic added
- duplicated logic added
- responsibility boundaries changed
- core abstraction changed
- tests became harder to write
- naming or structure hides intent

Confirmation examples:

- complexity check
- architecture boundary check
- testability review
- focused human design review

## 柔軟性

The PR may affect configurability, extensibility, environment differences, feature flags, rollout strategy, or future change cost.

Common signals:

- hard-coded policy added
- environment-specific behavior changed
- feature flag added or removed
- rollout or rollback behavior changed
- extension point changed

Confirmation examples:

- configuration test
- environment matrix test
- feature flag test
- rollback plan check

## 安全性

The PR may create risk of user harm, business stoppage, irreversible data damage, operational failure, or difficult recovery.

Common signals:

- delete or overwrite operation changed
- financial, legal, operational, or critical workflow changed
- irreversible side effect added
- admin or bulk operation changed
- failure may affect many users

Confirmation examples:

- fail-safe behavior test
- dry run
- permission and confirmation flow test
- rollback/recovery review
- release readiness review
