---
name: verify-review-findings
description: Verify and validate one or more pasted code review findings against repository evidence, separating confirmed behavior from domain and external-system assumptions; use in a separate repository-checking session, not for a fresh broad review or automatic remediation.
license: MIT
---

# Review Finding Verifier

## Purpose and boundary

Review findings are hypotheses to verify, not facts to accept. Investigate only the findings supplied by the user and determine which parts are supported by the checked-out repository, which parts depend on domain or operational knowledge, and which parts depend on systems outside the repository.

This skill is for a separate session in which the reviewer conversation is not available. The current checkout is the repository evidence scope. Do not start a new broad code review, invent additional findings, modify files, persist results, post review comments, or implement fixes.

If no finding is supplied, request at least one finding before investigating. If finding boundaries are genuinely ambiguous and splitting them differently could change the result, ask the user to clarify the boundaries rather than inventing them.

## Input handling

Accept one or more findings in any reasonable text format. Use supplied file paths, line numbers, symbols, evidence, scenario, severity, and suggested fix as search hints, but verify every such detail against the repository.

Assign stable IDs (`F1`, `F2`, …) in input order when IDs are absent. Keep every finding as a separate unit even when findings overlap. Do not treat a premise from one finding as an established fact for another finding; repeat the repository check for each claim, reusing only the search work, not the conclusion.

For each finding, extract three things before judging it:

- **Claim**: what behavior, consequence, or design concern is asserted.
- **Required conditions**: inputs, states, call paths, timing, permissions, data, or external behavior needed for the claim to hold.
- **Reviewer evidence**: facts the reviewer says support the claim.

Make implicit premises explicit. For example, “a deleted member can exchange points” may require: the member can reach the exchange operation, the operation does not reject the deleted state, and no later step rejects it.

## Investigation workflow

Perform the following for each finding, in order.

### 1. Confirm the target behavior

Locate the cited path, line, function, method, type, or distinctive text. If no target is supplied, search the repository from the claim and reviewer evidence. Read enough surrounding code to establish actual behavior, including:

- conditions, validation, early returns, authorization, and error handling;
- callers and reachable entry points;
- callees, state changes, transactions, and returned errors;
- input, data, and database constraints;
- relevant tests, configuration, schemas, API specifications, ADRs, README, and domain documentation.

Use repository search and normal code-reading tools first. Line numbers in the report must be observed from the checked-out files; never fabricate them. If the cited code is absent or materially different, state that explicitly.

### 2. Trace reachability and expected behavior

For every required condition, determine whether the repository establishes it. Inspect all relevant call sites and boundary layers, not only the function named by the reviewer. Look for protections such as middleware, validation, authorization, state-transition guards, repository behavior, database constraints, tests, and configuration.

Separate:

- the code path that can produce the alleged behavior;
- whether an input or state can reach that path;
- the expected result that makes the behavior a defect.

Do not call a public or contractually permitted input unreachable merely because no current caller was found. Conversely, do not call a state reachable merely because the target function can represent it; verify the entry path and constraints.

### 3. Search for rebuttal evidence

Actively look for evidence that prevents or changes the finding. At minimum, check the relevant callers, guards, validation, authorization, state transitions, persistence constraints, tests, configuration, and repository documentation. If documentation and implementation disagree, report both facts and do not choose one silently.

If every known caller applies a guard, treat that as a rebuttal only when the relevant entry point is closed to unexamined callers (for example, a private function or a fully enumerated route). If the function is publicly callable, exported, indirectly invoked, or its callers cannot be exhaustively identified, record the guard as repository evidence but keep the remaining reachability gap.

Do not promote issues discovered during this search into new findings. Mention related findings only when the relationship is needed to explain the evidence. If several supplied findings rely on the same cause or state transition, keep them separate and explicitly note the relationship.

### 4. Classify the evidence boundary

Label the basis of the conclusion as follows:

- **Code fact**: directly observable in the implementation, such as “the method does not read `member_status`.”
- **Repository fact**: established by repository-wide search or repository documentation, such as “all three HTTP callers pass through `ActiveMemberMiddleware`.”
- **Domain assumption**: a business rule, operational rule, lifecycle rule, or intended invariant not established by the repository.
- **External-system assumption**: behavior of an IdP, external API, queue, provider, or other system outside the repository.

Do not turn an assumption into a fact because it is common practice, plausible, or stated confidently by the reviewer. Repository documentation is evidence, but if it conflicts with implementation, preserve the conflict as an unknown or qualification.

## Classification

Assign exactly one final classification to each finding:

- **confirmed** — the claim follows from repository evidence, including reachability and expected behavior, with no conclusion-changing unverified premise.
- **likely** — repository evidence strongly supports the claim, but a limited gap prevents complete confirmation. Use sparingly and identify the remaining gap. Ask a suggested question when a human decision is needed.
- **domain-dependent** — the relevant code behavior is verified, but whether it is a problem depends on business rules, operations, lifecycle state, or another domain premise.
- **external-dependent** — the outcome depends on behavior or a contract of a system outside the repository.
- **unsupported** — adequate support was not found, or repository evidence contradicts the claim. In the reasoning, distinguish “not established” from “rebutted by counter-evidence.”
- **design-question** — the direct bug claim is not established or is not the main issue, but concrete repository evidence raises a worthwhile question about a domain model, state representation, responsibility boundary, API boundary, invariant, or data model. Do not use this for taste, generic best practices, or abstract refactoring preferences.

Use `confirmed` only when the repository itself establishes all material premises. A repository-owned API contract, schema, test oracle, or authoritative documentation can establish a rule that would otherwise look external or domain-dependent; cite that evidence and note any conflict with implementation. If a missing premise could make the current implementation correct, prefer `domain-dependent`, `external-dependent`, or `likely` as appropriate. A finding can be `design-question` even when the operational failure is not confirmed, but the design question must be tied to a concrete representation or responsibility in this repository.

Use these tie-breakers when evidence is incomplete:

- Choose `domain-dependent` when the code path and relevant behavior are clear, but whether the state is valid, reachable in operation, or harmful depends on an unconfirmed business or operational rule.
- Choose `likely` only when repository evidence strongly supports the path and expected outcome and the remaining gap is narrow, local, and not a potentially different domain contract.
- Choose `unsupported` when the target behavior or required condition is contradicted by repository evidence, or when the claim has no sufficient support after the relevant paths and constraints were checked. “No caller was found” alone is not enough to make a public or permitted input unsupported.
- Choose `external-dependent` when the decisive premise belongs to an outside system, unless a repository-owned contract or authoritative test fully establishes the expected behavior.
- Choose `design-question` when a concrete representation or responsibility warrants a design decision, even if a business rule remains unresolved; if the only issue is whether a rule applies, use `domain-dependent` instead.

## Output

Write the report in the user’s language. Start with a compact summary and then analyze every finding independently:

```markdown
Summary

- F1: domain-dependent
- F2: confirmed
- F3: design-question
```

When applicable, add one short note after the summary that identifies overlapping findings, for example: `F2とF4は同じ状態遷移を前提としており、同一原因の可能性があります。` Do not merge or omit either finding. Each detailed finding must repeat its own claim, evidence, assumptions, unknowns, and reasoning; the summary or another finding cannot supply missing support.

For each finding, use this structure:

```markdown
## F1 — domain-dependent

### Reviewer claim

<the claim, preserved faithfully and made precise if needed>

### Verified facts

- [Code fact] <fact with `path:line` or symbol when available>
- [Repository fact] <fact established by callers, tests, docs, schema, or configuration>

### Assumptions required

- [Domain assumption] <business or operational premise>
- [External-system assumption] <outside-system premise>

### Unknowns

- <only unknowns that could change the classification or practical conclusion>

### Reasoning

<explain which premises are established, which are not, and why the classification follows; distinguish absence of support from counter-evidence>

### Suggested question

<include only for domain-dependent, external-dependent, design-question, or a likely finding that requires human judgment>
```

Keep `Reviewer claim`, `Verified facts`, `Assumptions required`, `Unknowns`, and `Reasoning` for every finding, using `なし` where a section is genuinely empty. Include `Suggested question` only for domain-dependent, external-dependent, design-question, or a likely finding that requires human judgment. For `confirmed`, explicitly state why no material assumption remains. For `unsupported`, say whether the claim was merely unproven or was contradicted by a specific guard, caller, constraint, test, or document.

Suggested questions should obtain the missing judgment from the person who understands the implementation. They must not merely restate the reviewer claim. For domain questions, ask about the applicable rule and where that rule is guaranteed. For external questions, ask for the external contract or authoritative behavior. For design questions, ask whether the represented state, responsibility placement, or invariant is intentional and what boundary is supposed to guarantee it.

Do not spend the report on a repair design. A minimal follow-up or evidence source may be named in a suggested question, but the primary result is the evidence boundary and the remaining uncertainty.

## Final checks

Before returning the report, verify that:

- every supplied finding has exactly one classification and its own reasoning;
- the reviewer’s claim was decomposed into conditions and tested against both supporting and rebutting evidence;
- code facts, repository facts, domain assumptions, and external-system assumptions are not mixed;
- no unverified external behavior or domain rule was asserted as fact;
- no new review finding was added;
- paths and line numbers are accurate for the current checkout;
- unknowns are narrow enough for a human to resolve;
- questions appear only where human judgment is actually needed.
