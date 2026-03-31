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

2. Check for cc-sdd steering artifacts. If `.kiro/steering/` directory does not exist at all, warn but do not block:
   「cc-sdd の steering フェーズ（`/kiro:steering`）がまだ完了していないようです。」
   「tech.md が存在しない場合、Gap Fill 質問で技術スタックを入力できます。続行しますか？」

### Step 2: Tech Stack Auto-Extraction

Extract tech stack with the following priority:

**Priority 1: `.kiro/steering/tech.md`**

If this file exists, first perform **Sparse Detection**:

**Sparse Detection criteria** — tech.md is considered sparse/placeholder if ANY of:
- Core Technologies section contains placeholder text (lines matching `[e.g.,` or `[e.g.` or `例:`)
- Language line has no actual value (e.g., `- **Language**: [e.g., TypeScript, Python]` or `- **Language**:` with nothing after the colon)
- Framework line has no actual value
- Runtime line has no actual value
- Architecture section contains only `[High-level system design approach]` or is empty

If tech.md is **fully populated** (passes all sparse checks):

Parse it for:

- **Languages**: Search for "Language" / "言語" headings or list items. Extract technology names (e.g., TypeScript, Python).
- **Frameworks**: Search for "Framework" / "フレームワーク" headings or list items. Also extract from "Key Libraries" section. Extract technology names (e.g., Next.js, NestJS, LangGraph).
- **Tools**: Search for "Required Tools" / "ツール" / "Development Environment" headings. Extract tool names (e.g., Docker, Playwright, AWS).

Set `tech_stack_source: "steering"` in manifest.
→ Continue to **After extraction** below.

If tech.md is **sparse/placeholder**:

「`.kiro/steering/tech.md` が検出されましたが、技術スタックがまだ記入されていないようです。」
「Gap Fill 質問で技術スタックを入力します。」
→ Trigger **Gap Fill** below.

If tech.md **does not exist**:
→ Trigger **Gap Fill** below.

**Priority 2: `$PROJECT_ROOT/CLAUDE.md` の Tech Stack 行**

If Priority 1 was fully populated → skip this step (already extracted).

If Priority 1 triggered Gap Fill → skip this step (Gap Fill handles it).

Otherwise (tech.md does not exist and Gap Fill was not yet triggered), search CLAUDE.md for a line matching `**Tech Stack:**` or `## Tech Stack`.
Parse the value by splitting on commas (`,`) and pipes (`|`).
Classify each item by matching against Language-Specific, Framework-Specific, and Tool-Specific keywords from shared spec.

If result contains actual technology names (not just "(TBD" placeholder):
  Set `tech_stack_source: "claude_md"` in manifest.
  → Continue to **After extraction** below.

If CLAUDE.md has no usable tech stack:
  → Trigger **Gap Fill** below.

**Priority 3: Gap Fill（構造化質問 → tech.md 生成）**

Display:

「技術スタックを教えてください。未定の項目は「未定」と記載してください。」

Present the following structured prompt using AskUserQuestion:

```
- Architecture: (例: Monorepo / Frontend only / Fullstack)
- Language: (例: TypeScript, Python)
- Framework: (例: Next.js 15, Hono, FastAPI)
- Runtime: (例: Node.js 22+, Python 3.12+)
- Key Libraries: (例: TanStack Query, LangGraph, Prisma)
- Infrastructure: (例: AWS, Vercel, Cloudflare)
- DevOps/Monitoring: (例: GitHub Actions, Datadog)
- Testing: (例: Vitest, Playwright, pytest)

備考欄（任意）:
(例: 最新安定バージョン希望、既存のXXXと統合予定、など)
```

After receiving user input, generate tech.md content in **cc-sdd template format**:

```markdown
# Technology Stack

## Architecture
[from Architecture input — or "[To be determined during spec-design]" if 未定]

## Core Technologies
- **Language**: [from Language input]
- **Framework**: [from Framework input]
- **Runtime**: [from Runtime input]

## Key Libraries
[from Key Libraries input — or "[To be determined during spec-design]" if 未定]

## Development Standards
### Type Safety
[inferred from language choice — e.g., "TypeScript strict mode, no `any`" for TypeScript; "Type hints required (mypy strict)" for Python; "[To be determined]" for others]
### Code Quality
[inferred from framework/language — e.g., "ESLint, Prettier" for JS/TS ecosystem; "Ruff, Black" for Python; "[To be determined]" for others]
### Testing
[from Testing input — or "[To be determined during spec-design]" if 未定]

## Development Environment
### Required Tools
[from Infrastructure + DevOps/Monitoring input]
### Common Commands
```bash
# Dev: [inferred from framework — e.g., `npm run dev` for Next.js, `uv run fastapi dev` for FastAPI]
# Build: [inferred from framework]
# Test: [inferred from Testing input]
```

## Key Technical Decisions
[from 備考欄 input — or "[To be determined during spec-design]" if empty]
```

Display generated content and ask for confirmation:

「以下の内容で `.kiro/steering/tech.md` を生成します。修正がある場合は指摘してください（Enter で確定）:」

[Display generated tech.md content]

If user provides modifications, apply them to the generated content.

Write confirmed content to `.kiro/steering/tech.md` (create `.kiro/steering/` directory with `mkdir -p` if needed).

「✅ `.kiro/steering/tech.md` を生成しました。」

Now re-parse the generated tech.md using the same Priority 1 extraction logic (Languages, Frameworks, Tools).

Items marked as 「未定」or placeholders like `[To be determined during spec-design]` should be treated as empty values and stored as empty arrays for that category.

Set `tech_stack_source: "gap_fill"` in manifest.

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

**Update settings.json — パッケージマネージャー権限の自動追加:**

Infer package manager from confirmed `tech_stack.languages` and `tech_stack.frameworks`, then add permissions to `$PROJECT_CLAUDE/settings.json` `allow` list:

| Language / Framework | Package Manager | Permissions |
| --- | --- | --- |
| TypeScript, JavaScript | (ask user) npm / pnpm / yarn / bun | See mapping below |
| Python | (ask user) uv / pip | See mapping below |
| Rust | cargo | `"Bash(cargo *)"` |
| Go | go | `"Bash(go *)"` |
| Java, Kotlin | (ask user) maven / gradle | See mapping below |
| PHP | composer | `"Bash(composer *)"`, `"Bash(php *)"` |
| C#, .NET | dotnet | `"Bash(dotnet *)"` |
| C, C++ | cmake | `"Bash(cmake *)"`, `"Bash(make *)"` |

Permission mapping:
- npm → `"Bash(npm *)"`, `"Bash(npx *)"`
- pnpm → `"Bash(pnpm *)"`, `"Bash(npx *)"`
- yarn → `"Bash(yarn *)"`
- bun → `"Bash(bun *)"`, `"Bash(bunx *)"`
- uv → `"Bash(uv *)"`, `"Bash(python *)"`
- pip → `"Bash(pip *)"`, `"Bash(python *)"`
- cargo → `"Bash(cargo *)"`
- go → `"Bash(go *)"`
- maven → `"Bash(mvn *)"`, `"Bash(mvnw *)"`
- gradle → `"Bash(gradle *)"`, `"Bash(gradlew *)"`
- composer → `"Bash(composer *)"`, `"Bash(php *)"`
- dotnet → `"Bash(dotnet *)"`
- cmake → `"Bash(cmake *)"`, `"Bash(make *)"`

If the language has multiple package manager options (e.g., TypeScript → npm/pnpm/yarn/bun), ask user:

「パッケージマネージャーを選択してください（{language}）:」with options listed.

If package manager can be uniquely inferred (e.g., Rust → cargo), add without asking.

Add only permissions not already present in the `allow` list. Display added permissions:

「✅ settings.json にパッケージマネージャー権限を追加しました: {permissions}」

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

1. **cc-sdd: 設計フェーズを開始**
   - `/kiro:spec-design <feature>` — アーキテクチャ設計（Discovery で技術調査・提案）

2. **steering 同期（設計結果の反映）**
   - `/kiro:steering` — spec-design の技術決定を tech.md に反映（sync モード）
   - 技術スタックに大きな変更があった場合は `/ecc-configure` を再実行

3. **cc-sdd: タスク分解・実装**
   - `/kiro:spec-tasks <feature>` — タスク分解
   - `/kiro:spec-impl <feature> <task-ids>` — 実装

4. **TDD ワークフロー**
   - `/tdd` — テスト駆動開発
   - `/code-review` — コードレビュー

5. **継続改善**
   - `/ecc-evolve` — ECC 更新同期 + 継続改善コンポーネント
```
