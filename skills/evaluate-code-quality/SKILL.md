---
name: evaluate-code-quality
description: Evaluate pull requests, code diffs, implementation summaries, release candidates, or AI-generated code before human review. Produce a focused Quality Evidence Pack covering core correctness and test risks plus at most two change-specific quality characteristics. Use for PR review preparation, risk-based review, quality gates, and review burden reduction.
license: MIT
---

# PR Quality Evaluator

## Purpose

Prepare evidence for human review. Do not approve or reject the change.

Perform one mandatory **core evaluation** covering:

- change intent and scope
- likely behavioral failures and edge cases
- test adequacy and missing tests
- areas requiring human judgment
- uncertainty and overall risk

After collecting evidence, select **at most two** quality characteristics that have the strongest diff-specific evidence. Evaluate the core and selected characteristics independently. Do not mechanically score all characteristics and do not add a characteristic merely to fill the limit.

## Required references

Read these files before evaluating:

- [references/runtime-input-prompt.md](references/runtime-input-prompt.md) for the evaluation contract and input rules
- [references/quality-characteristics.md](references/quality-characteristics.md) for selecting up to two characteristics
- [references/risk-rules.md](references/risk-rules.md) for risk classification
- [references/output-template.md](references/output-template.md) for the final format

Apply the core-plus-two contract in this file as the controlling rule. Use the references for the detailed characteristic definitions, risk rules, runtime inputs, and output shape.

## Execution path

1. Extract the PR identifier: PR number, URL, `staged`, or empty for the current HEAD diff.
2. Check once whether a Workflow tool that can execute the script below is actually available.
3. If available, invoke it once with `args: {"pr_input": "<value>"}`.
4. If unavailable, use the short fallback. Do not retry, emulate, or claim independent parallel evaluation.
5. Display the report to the user. Post it to a PR only when explicitly requested.

## Evidence collection rules

For a PR:

- Read metadata with `gh pr view <id> --json title,body,files`.
- Read per-file patches with `gh api repos/{owner}/{repo}/pulls/{number}/files --paginate`. Do not use `gh pr diff <id> -- <file>`, because file filtering is not supported consistently.
- Read automated-check evidence with `gh pr checks <id>`. If the caller already supplied CI results through the runtime prompt, use them as additional input without rerunning anything.
- Do not run local tests, lint, builds, benchmarks, dependency installation, or code generation.
- Record pending or failing checks as CI evidence. Record only absent or unavailable relevant checks as missing input.

For `staged` or HEAD:

- Use the corresponding per-file `git diff` commands.
- Do not run local checks. If the user did not provide test results, record test evidence as unavailable.

Skip generated or vendored content during semantic review, but record the files and inspect generated type definitions only when needed to assess a non-generated change.

## Short fallback when Workflow is unavailable

1. Collect metadata, changed files, non-generated per-file diffs, test-file presence, and CI evidence using the rules above.
2. Perform the core evaluation.
3. Select zero to two quality characteristics using the selection rules in `quality-characteristics.md`; evaluate only those selected.
4. Classify risk using `risk-rules.md`.
5. Render `output-template.md` and state `Workflow未利用の短縮評価` under low-confidence areas.

## Workflow script

Invoke the Workflow tool with this exact script:

```javascript
export const meta = {
  name: 'evaluate-code-quality',
  description: 'Core PR evaluation plus up to two evidence-selected quality characteristics',
  phases: [
    { title: 'スキャン', detail: 'PR情報・diff・CI結果の収集と特性選定' },
    { title: '品質評価', detail: 'コア評価と最大2特性の独立並列評価' },
    { title: 'リスク分析', detail: '結果統合とリスク分類' },
    { title: 'レポート生成', detail: 'Quality Evidence Pack生成' },
  ],
}

phase('スキャン')

const prInput = args && args.pr_input ? args.pr_input : ''

const scanResult = await agent(`
Collect evidence for a first-pass PR quality evaluation.

PR_INPUT: ${prInput || '(none — use git diff HEAD)'}

For a PR:
- Run gh pr view <id> --json title,body,files.
- Fetch file patches with gh api repos/{owner}/{repo}/pulls/{number}/files --paginate.
- Run gh pr checks <id> and capture its output even when a check is pending or failing.
- If the caller supplied CI results, use them as additional evidence without rerunning checks.
- Do not run local tests, lint, builds, benchmarks, dependency installation, or code generation.

For "staged", use per-file git diff --cached. Otherwise use per-file git diff HEAD.
For staged or HEAD, do not run local checks; record test evidence as unavailable unless supplied.

Skip semantic analysis of generated and vendored content. Record every changed file.
For each business-logic file, identify a corresponding test file and whether the changed behavior is covered.
Record truncated or unavailable patches. Note any "_ = value" suppression and any newly changed compound condition with its call site.

Perform characteristic selection after inspecting the diff. Select zero to two only:
- 機能適合性: business rule, validation, calculation, condition, or expected behavior
- 性能効率性: query, loop, bulk path, cache, or processing-volume behavior
- 互換性: API/schema/data/event/config/dependency contract
- 相互作用性: UI, navigation, visible wording, accessibility, or user flow
- 信頼性: failure handling, retry, timeout, transaction, idempotency, or concurrency
- セキュリティ: auth/authz, sensitive data, input boundary, secrets, permissions, or external communication
- 保守性: architecture boundary, complexity, duplication, coupling, or testability
- 柔軟性: configuration, feature flag, environment variation, rollout, or extension point
- 安全性: irreversible data or operational harm, financial/legal flow, admin or bulk action

Choose only characteristics with concrete diff evidence. Rank by potential harm, breadth, irreversibility, and uncertainty. Do not select a characteristic just to fill the limit.

Return JSON with:
- pr_title: string
- pr_body: string
- change_type: string
- changed_files: string[]
- business_logic_diffs: string
- test_coverage_notes: string
- ci_results: string
- missing_inputs: string
- selected_characteristics: array of at most 2 objects { key: string, reason: string }
`, {
  schema: {
    type: 'object',
    required: ['pr_title', 'pr_body', 'change_type', 'changed_files', 'business_logic_diffs', 'test_coverage_notes', 'ci_results', 'missing_inputs', 'selected_characteristics'],
    properties: {
      pr_title: { type: 'string' },
      pr_body: { type: 'string' },
      change_type: { type: 'string' },
      changed_files: { type: 'array', items: { type: 'string' } },
      business_logic_diffs: { type: 'string' },
      test_coverage_notes: { type: 'string' },
      ci_results: { type: 'string' },
      missing_inputs: { type: 'string' },
      selected_characteristics: {
        type: 'array',
        maxItems: 2,
        items: {
          type: 'object',
          required: ['key', 'reason'],
          properties: {
            key: { type: 'string' },
            reason: { type: 'string' },
          },
        },
      },
    },
  },
})

const allowedCharacteristics = new Set([
  '機能適合性', '性能効率性', '互換性', '相互作用性', '信頼性',
  'セキュリティ', '保守性', '柔軟性', '安全性',
])
const seenCharacteristics = new Set()
const selectedCharacteristics = (scanResult.selected_characteristics || [])
  .filter(x => allowedCharacteristics.has(x.key) && !seenCharacteristics.has(x.key) && seenCharacteristics.add(x.key))
  .slice(0, 2)

log(`変更種別: ${scanResult.change_type} | 選定特性: ${selectedCharacteristics.map(x => x.key).join(', ') || 'なし'}`)

phase('品質評価')

const coreTask = () => agent(`
Evaluate the PR core only. Do not score software quality characteristics.

Title: ${scanResult.pr_title}
Body: ${scanResult.pr_body}
Change type: ${scanResult.change_type}
Changed files: ${scanResult.changed_files.join(', ')}
Test coverage: ${scanResult.test_coverage_notes}
CI: ${scanResult.ci_results}
Missing inputs: ${scanResult.missing_inputs}

Diff:
${scanResult.business_logic_diffs}

Return Japanese JSON with:
- change_summary: string
- change_reason: string
- impact_scope: string[]
- likely_failures: string[]
- recommended_tests: array of { priority: "高"|"中"|"低", test_name: string, what_it_verifies: string, automatable: "できる"|"難しい"|"人間確認" }
- human_focus_points: string[]
- uncertainty_notes: string[]

Use concrete diff evidence. Distinguish existing CI evidence from proposed tests. Do not infer unavailable behavior.
`, {
  schema: {
    type: 'object',
    required: ['change_summary', 'change_reason', 'impact_scope', 'likely_failures', 'recommended_tests', 'human_focus_points', 'uncertainty_notes'],
    properties: {
      change_summary: { type: 'string' },
      change_reason: { type: 'string' },
      impact_scope: { type: 'array', items: { type: 'string' } },
      likely_failures: { type: 'array', items: { type: 'string' } },
      recommended_tests: {
        type: 'array',
        items: {
          type: 'object',
          required: ['priority', 'test_name', 'what_it_verifies', 'automatable'],
          properties: {
            priority: { type: 'string', enum: ['高', '中', '低'] },
            test_name: { type: 'string' },
            what_it_verifies: { type: 'string' },
            automatable: { type: 'string', enum: ['できる', '難しい', '人間確認'] },
          },
        },
      },
      human_focus_points: { type: 'array', items: { type: 'string' } },
      uncertainty_notes: { type: 'array', items: { type: 'string' } },
    },
  },
})

const characteristicTasks = selectedCharacteristics.map(selected => () => agent(`
Evaluate only the selected quality characteristic. Do not perform the core evaluation or discuss other characteristics.

Characteristic: ${selected.key}
Selection reason: ${selected.reason}
Title: ${scanResult.pr_title}
Changed files: ${scanResult.changed_files.join(', ')}
Test coverage: ${scanResult.test_coverage_notes}
CI: ${scanResult.ci_results}
Missing inputs: ${scanResult.missing_inputs}

Diff:
${scanResult.business_logic_diffs}

Return Japanese JSON with:
- characteristic: string
- selection_reason: string
- impact_reason: string
- confirmation_method: string
- uncertainty_notes: string

Use specific file or code evidence. Prefer 不明な点の明示 over guessing.
`, {
  schema: {
    type: 'object',
    required: ['characteristic', 'selection_reason', 'impact_reason', 'confirmation_method', 'uncertainty_notes'],
    properties: {
      characteristic: { type: 'string' },
      selection_reason: { type: 'string' },
      impact_reason: { type: 'string' },
      confirmation_method: { type: 'string' },
      uncertainty_notes: { type: 'string' },
    },
  },
}))

const parallelResults = await parallel([coreTask, ...characteristicTasks])
const coreResult = parallelResults[0]
const characteristicResults = parallelResults.slice(1).filter(Boolean)

phase('リスク分析')

const riskResult = await agent(`
Classify the review risk from the evidence below. Do not approve or reject the PR.

Context:
- title: ${scanResult.pr_title}
- change type: ${scanResult.change_type}
- missing inputs: ${scanResult.missing_inputs}
- CI: ${scanResult.ci_results}

Core evaluation:
${JSON.stringify(coreResult, null, 2)}

Selected characteristic evaluations:
${JSON.stringify(characteristicResults, null, 2)}

Classify 高 when auth/authz, sensitive/payment data, migration/bulk delete, external async integration,
retry/idempotency/transaction/recovery, hard rollback, broad untested impact, or important uncertainty is involved.
Otherwise classify 中 for multi-layer behavior changes, API/UI/business-rule/dependency changes, changed branching,
weak edge-case coverage, or maintainability/compatibility/reliability impact.
Classify 低 only for narrow reversible changes whose main risks are covered by available automated evidence.
When genuinely uncertain, choose one level higher.

Return Japanese JSON with:
- risk_level: "低"|"中"|"高"
- rationale: string
- review_focus_points: string[]
- automated_checks_ok: string[]
- must_check_before_merge: string[]
- low_confidence_areas: string[]
`, {
  schema: {
    type: 'object',
    required: ['risk_level', 'rationale', 'review_focus_points', 'automated_checks_ok', 'must_check_before_merge', 'low_confidence_areas'],
    properties: {
      risk_level: { type: 'string', enum: ['低', '中', '高'] },
      rationale: { type: 'string' },
      review_focus_points: { type: 'array', items: { type: 'string' } },
      automated_checks_ok: { type: 'array', items: { type: 'string' } },
      must_check_before_merge: { type: 'array', items: { type: 'string' } },
      low_confidence_areas: { type: 'array', items: { type: 'string' } },
    },
  },
})

phase('レポート生成')

const report = await agent(`
Generate the final Japanese Quality Evidence Pack. Output only Markdown.

Scan:
${JSON.stringify(scanResult, null, 2)}

Core:
${JSON.stringify(coreResult, null, 2)}

Selected characteristics (zero to two; output only these rows):
${JSON.stringify(characteristicResults, null, 2)}

Risk:
${JSON.stringify(riskResult, null, 2)}

Use this structure:

# AI一次評価: Quality Evidence Pack

## 1. 変更概要
- 何を変えたか:
- なぜ変えたか:
- 変更種別:
- 主な変更ファイル:
- 入力として確認できた情報:
- 入力として不足している情報:

## 2. コア評価
### 影響範囲
### 失敗しそうなケース
### 追加すべきテスト
| 優先度 | テスト内容 | 確認したいこと | 自動化 |
### 人が重点的に見るべき箇所

## 3. 選定した品質特性
| 品質特性 | 選定理由 | 影響理由 | 確認方法 |

If none were selected, write "追加の品質特性は選定されませんでした。"

## 4. AI評価の自信が低い箇所

## 5. レビュー方針
- リスク分類:
- 分類理由:
- レビューで重点的に見る点:
- 自動検査に任せてよい点:
- マージ前に必須で確認すべき点:

Put important risks first. Keep bullets short and actionable. Use only PR-specific evidence.
Write "入力情報からは確認できません" when evidence is absent.
`)

return report
```

## Core rules

- Treat the result as review preparation, not a verdict.
- Keep the core evaluation mandatory and quality-characteristic selection capped at two.
- Prefer no specialist characteristic over a weakly justified one.
- Separate observed diff/CI evidence, proposed checks, and human judgment.
- Avoid generic warnings and minor style comments.
- Expose uncertainty instead of inventing behavior.
- Match the user's language; default to Japanese.
