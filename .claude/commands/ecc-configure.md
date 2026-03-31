---
description: "Auto-extract tech stack + install downstream (implementation) ECC components. Run AFTER cc-sdd steering."
---

# ECC Configure — Tech Stack Extraction + Downstream Installer

## Prerequisites

Read `docs/ecc-shared-spec.md` for: path resolution, ECC detection, scan engine, classification criteria (configure mode), classification keywords, scoring algorithm (configure mode), project type, phase presentation, manifest schema, and operational notes. Follow that spec exactly for all shared operations.

## Output Language

All user-facing output (messages, tables, prompts, reports) MUST be in Japanese.

## Flow

### Step 1: Precondition Check

1. Read `$MANIFEST_PATH`. If bootstrap not completed (`phases.upstream.installed_at` is null), stop:
   「先に `/ecc-bootstrap` を実行してください。」

2. Check for cc-sdd steering artifacts. If `.kiro/steering/tech.md` does not exist, warn but do not block:
   「cc-sdd の steering フェーズ（`/kiro:steering`）がまだ完了していないようです。」
   「技術スタックの自動抽出ができない場合、手動入力が必要になります。続行しますか？」

### Step 2: Tech Stack Auto-Extraction

Extract tech stack with the following priority:

**Priority 1: `.kiro/steering/tech.md`**

If this file exists, parse it for:

- **Languages**: Search for "Language" / "言語" headings or list items. Extract technology names (e.g., TypeScript, Python).
- **Frameworks**: Search for "Framework" / "フレームワーク" headings or list items. Also extract from "Key Libraries" section. Extract technology names (e.g., Next.js, NestJS, LangGraph).
- **Tools**: Search for "Required Tools" / "ツール" / "Development Environment" headings. Extract tool names (e.g., Docker, Playwright, AWS).

Set `tech_stack_source: "steering"` in manifest.

**Priority 2: `$PROJECT_ROOT/CLAUDE.md` の Tech Stack 行**

If Priority 1 not available, search CLAUDE.md for a line matching `**Tech Stack:**` or `## Tech Stack`.
Parse the value by splitting on commas (`,`) and pipes (`|`).
Classify each item by matching against Language-Specific, Framework-Specific, and Tool-Specific keywords from shared spec.

Set `tech_stack_source: "claude_md"` in manifest.

**Priority 3: Manual fallback（Q1-Q3）**

If neither Priority 1 nor 2 yields results:

「技術スタックの自動検出に失敗しました。手動で入力してください。」

Scan ECC to dynamically build available options:

- `$ECC_ROOT/rules/` subdirectory names → available **languages** list
  - Example: `common/`, `typescript/`, `python/` → TypeScript, Python
- `$ECC_ROOT/skills/*/SKILL.md` descriptions → available **frameworks/libraries** list
  - Extract framework names from descriptions (Next.js, Django, Flask, Docker, etc.)

Use AskUserQuestion for each:

**Q1: Languages** (multi-select from scan results)
「使用する言語を選択してください（カンマ区切りで入力）:」followed by the discovered language list.

**Q2: Frameworks/Libraries** (multi-select, filtered by Q1 + language-agnostic options)
「使用するフレームワーク/ライブラリを選択してください（カンマ区切りで入力）:」followed by relevant options based on Q1 answers.

**Q3: Tools/Infrastructure** (multi-select, filtered by project type)
「使用するツール/インフラを選択してください（カンマ区切りで入力）:」followed by relevant options (docker, postgres, playwright, supabase, etc.) with project type recommendations highlighted.

Set `tech_stack_source: "manual"` in manifest.

**After extraction (all priorities):**

- Save to manifest `project.tech_stack` (languages, frameworks, tools)
- Update CLAUDE.md: If `$PROJECT_ROOT/CLAUDE.md` contains "(TBD" placeholder, replace with actual tech stack composed from languages + frameworks + tools
- Display extraction result:

「✅ Tech Stack 検出（ソース: {source}）:」
「  Languages: [{languages}]」
「  Frameworks: [{frameworks}]」
「  Tools: [{tools}]」

- Ask for confirmation:

「Tech Stack は正しいですか？ 修正がある場合は入力してください（Enter で確定）:」

If user provides modifications, update the tech_stack accordingly.

### Step 3: Run Scan Engine (Configure Mode)

Execute scan engine per shared spec. Classify components using **configure mode**. Apply configure mode scoring per shared spec **strictly** based on the extracted `tech_stack` and `project.type`. Sort components by score within each phase.

### Step 4: Phase-based Diff Display

Compare scan results against manifest `installed[]`. Display results grouped by Phase (component type) per shared spec Phase Presentation format.

Each component shows a status alongside its score:

| Status | Meaning |
| --- | --- |
| **INSTALL** | New component, not yet installed |
| **SKIP** | Already installed (same phase) |
| **ALREADY INSTALLED** | Installed during bootstrap (upstream phase) |

```markdown
### Phase A: Skills — 実装パターン

#### ⭐⭐⭐ 強く推薦
| # | Component | Status | 説明 | 根拠 |
| --- | --- | --- | --- | --- |
| 1 | (name) | INSTALL | (description) | (match reason) |

#### ⭐⭐ 推薦
| # | Component | Status | 説明 | 根拠 |
| --- | --- | --- | --- | --- |

### Phase B: Agents — 専門レビュアー・ビルダー
(same format)

### Phase C: Rules — コーディング規約
(language-specific rules: typescript/, python/, etc.)

### Phase D: Commands — ワークフロー
(same format)

### Phase E: MCP Servers — 外部ツール連携
(same format, ⚠️ mark servers requiring API keys)
```

Skip empty phases silently.

### Step 5: User Approval → Install → Update Manifest → Generate Report

Per phase, prompt user with selection syntax from shared spec:

「Phase X: (Phase Name) — インストールするコンポーネントを選択してください:」

- 番号指定: `1,2,3,5-8`
- `recommended` — ⭐⭐⭐ + ⭐⭐ を全選択
- `all` — 全てインストール
- `info <番号>` — 詳細を表示
- `skip` — このフェーズをスキップ

After selection:

- Copy approved components to destinations per shared spec
- MCP components: merge into `$PROJECT_CLAUDE/settings.json` under `mcpServers` key. Warn about required API keys.
- Update manifest: set `phases.downstream.installed_at`, add entries to `installed[]` with phase ("downstream"), score, add scan entry to `scans[]` with `scan_mode: "configure"`
- Generate report to `$REPORT_DIR/configure-YYYY-MM-DD.md`

Report includes:

1. **Tech Stack** — 検出ソースと確定した tech stack
2. **Scan Summary** — Total scanned, match counts
3. **Phase-based Results** — Phase A-E ごとのインストール結果
4. **Coverage Analysis** — 言語/FW/ツールごとのカバレッジ
5. **Next Steps** — 以下の内容を出力:

```markdown
## Next Steps

1. **cc-sdd: 設計・実装フェーズを開始**
   - `/kiro:spec-design <feature>` — アーキテクチャ設計
   - `/kiro:spec-tasks <feature>` — タスク分解
   - `/kiro:spec-impl <feature> <task-ids>` — 実装

2. **TDD ワークフロー**
   - `/tdd` — テスト駆動開発
   - `/code-review` — コードレビュー

3. **継続改善**
   - `/ecc-evolve` — ECC 更新同期 + 継続改善コンポーネント
```
