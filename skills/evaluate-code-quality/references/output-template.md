# Output template

Use this structure for the final PR comment. Keep the headings stable.

```md
# AI一次評価

## 1. 変更概要
- 何を変えたか:
- なぜ変えたか:
- 変更種別:
- 主な変更ファイル:
- 入力として確認できた情報:
- 入力として不足している情報:

## 2. コア評価

### 影響範囲
-

### 失敗しそうなケース
-

### 追加すべきテスト
| 優先度 | テスト内容 | 確認したいこと | 自動化 |
|---|---|---|---|
| 高/中/低 |  |  | できる/難しい/人間確認 |

### 人が重点的に見るべき箇所
-

## 3. 選定した品質特性

| 品質特性 | 選定理由 | 影響理由 | 確認方法 |
|---|---|---|---|
| 選定した特性のみ（0〜2行） |  |  |  |

選定対象がない場合は「追加の品質特性は選定されませんでした。」と記載する。

## 4. AI評価の自信が低い箇所
-

## 5. レビュー方針
- リスク分類: 低 / 中 / 高
- 分類理由:
- レビューで重点的に見る点:
- 自動検査に任せてよい点:
- マージ前に必須で確認すべき点:
```

## Writing guidance

- Put the most important risks first.
- Keep each bullet short and actionable.
- Avoid generic warnings.
- If there is no evidence, write `入力情報からは確認できません`.
- If test results are provided, say whether they support the evaluation.
- Always include the core evaluation.
- Include zero to two selected quality-characteristic rows; never output all nine mechanically.
