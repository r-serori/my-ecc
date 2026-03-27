---
description: "Install Tier 0 (safety) + Tier 1 (design knowledge) ECC components. Run BEFORE cc-sdd."
---

# ECC Bootstrap — Tier 0 + Tier 1 Installer

## Prerequisites

Read `docs/ecc-shared-spec.md` for: path resolution, ECC detection, scan engine, classification criteria, classification keywords, scoring algorithm, project type, phase presentation, manifest schema, and operational notes. Follow that spec exactly for all shared operations.

## Output Language

All user-facing output (messages, tables, prompts, reports) MUST be in Japanese.

## Flow

### Step 1: Path Resolution & ECC Detection

Resolve paths per shared spec. If ECC not found, display the error message from shared spec and stop.

### Step 2: Manifest Check

Read `$MANIFEST_PATH`. If it exists and bootstrap has already been completed (`tiers.tier0.installed_at` or `tiers.tier1.installed_at` is set), ask the user to confirm re-execution:

「bootstrap は既に実行済みです。再実行しますか？」

### Step 3: Initial Setup (only if manifest does not exist)

#### 3a: Discover Options via ECC Scan

Scan ECC to dynamically build available options:

- `$ECC_ROOT/rules/` subdirectory names → available **languages** list
  - Example: `common/`, `typescript/`, `python/` → TypeScript, Python
- `$ECC_ROOT/skills/*/SKILL.md` descriptions → available **frameworks/libraries** list
  - Extract framework names from descriptions (Next.js, Django, Flask, Docker, etc.)
- `$ECC_ROOT/.agents/skills/*/agents/openai.yaml` → supplement with display_name, short_description
- `$ECC_ROOT/agents/*.md` names → language-specific **agents** list
- `$ECC_ROOT/mcp-configs/mcp-servers.json` keys → available **MCP servers** list
  - Extract server name + description from each JSON entry
  - Flag servers with `env` field as "API Key required"

#### 3b: Ask User

Use AskUserQuestion for each:

**Q0: Project Type** (single-select)

「プロジェクトの種類を選択してください:」

1. Frontend（SPA / SSR / Static サイト）
2. Backend（API / CLI / Worker）
3. Fullstack（Frontend + Backend）
4. Library / Package（ライブラリ / パッケージ）
5. Infrastructure / DevOps
6. Data / ML Pipeline

**Q1: Languages** (multi-select from scan results)

「使用する言語を選択してください（カンマ区切りで入力）:」followed by the discovered language list.

**Q2: Frameworks/Libraries** (multi-select, filtered by Q1 + language-agnostic options)

「使用するフレームワーク/ライブラリを選択してください（カンマ区切りで入力）:」followed by relevant options based on Q1 answers.

**Q3: Tools/Infrastructure** (multi-select, filtered by project type)

「使用するツール/インフラを選択してください（カンマ区切りで入力）:」followed by relevant options (docker, postgres, playwright, supabase, etc.) with project type recommendations highlighted.

#### 3c: Initialize Manifest

Create `$MANIFEST_PATH` with the manifest schema from shared spec. Save user answers:

- Q0 → `project.type`
- Q1 → `project.tech_stack.languages`
- Q2 → `project.tech_stack.frameworks`
- Q3 → `project.tech_stack.tools`

#### 3d: Update CLAUDE.md Tech Stack

If `$PROJECT_ROOT/CLAUDE.md` exists and contains "(TBD — /ecc-bootstrap で設定されます)":

Replace with actual tech stack composed from Q1 (languages) + Q2 (frameworks) + Q3 (tools).

### Step 4: Run Scan Engine

Execute scan engine per shared spec. Classify all components into tiers. Filter results for **Tier 0 and Tier 1 only**. Apply scoring algorithm per shared spec. Sort components by score within each phase.

### Step 5: Present Recommendations (Phase-based)

Display scored components grouped by Tier, then by Phase (component type) per shared spec Phase Presentation format.

```markdown
## Tier 0: Safety

### Phase A: Skills
| # | Component | Score | 説明 | 根拠 |
| --- | --- | --- | --- | --- |

### Phase C: Rules
| # | Component | Score | 説明 | 根拠 |
| --- | --- | --- | --- | --- |

## Tier 1: Design Knowledge

### Phase A: Skills — 設計知識・パターン

#### ⭐⭐⭐ 強く推薦
| # | Component | 説明 | 根拠 |
| --- | --- | --- | --- |
| 1 | (name) | (description) | (match reason) |

#### ⭐⭐ 推薦
| # | Component | 説明 | 根拠 |
| --- | --- | --- | --- |

#### ⭐ 任意
...

#### 📦 ドメイン特化（確認が必要）
...

### Phase B: Agents — 専門レビュアー・ビルダー
(same format per phase)

### Phase C: Rules — コーディング規約
(Rules are auto-determined by language. common/ is always installed.)

### Phase D: Commands — ワークフロー
(same format per phase)

### Phase E: MCP Servers — 外部ツール連携
(⚠️ mark servers requiring API keys)
```

Per phase, prompt user with selection syntax from shared spec:

「Phase X: (Phase Name) — インストールするコンポーネントを選択してください:」

- 番号指定: `1,2,3,5-8`
- `recommended` — ⭐⭐⭐ + ⭐⭐ を全選択
- `all` — 全てインストール
- `info <番号>` — 詳細を表示
- `skip` — このフェーズをスキップ

Skip empty phases silently.

### Step 6: Install

Copy approved components to destinations per shared spec. Create directories with `mkdir -p` as needed.

MCP components: Read existing `$PROJECT_CLAUDE/settings.json`, add approved servers under `mcpServers` key, write back formatted JSON. Never overwrite other settings.

For MCP servers with `env` field, display:

「⚠️ (server_name) には以下の環境変数の設定が必要です: (env_keys)」
「設定方法: export KEY=value または .env ファイルに追加」

### Step 7: Update Manifest

Record each installed component with: type, name, source, destination, tier, domain, score, reason, installed_at (ISO 8601). Set `tiers.tier0.installed_at` and `tiers.tier1.installed_at`. Record `ecc.commit_hash` and `ecc.last_sync`. Add scan entry to `scans[]`.

### Step 8: Generate Report

Output to `$REPORT_DIR/bootstrap-YYYY-MM-DD.md`:

1. **Scan Summary** — Total scanned, counts per tier
2. **Phase-based Results** — Phase A-E ごとのインストール結果
3. **Coverage Analysis** — Coverage per knowledge domain
4. **Gaps** — Uncovered domains and recommendations
5. **Next Steps** — Instructions to start cc-sdd
