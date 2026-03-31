---
description: "Install upstream (safety + design knowledge) ECC components. Run BEFORE cc-sdd."
---

# ECC Bootstrap — Upstream Component Installer

## Prerequisites

Read `docs/ecc-shared-spec.md` for: path resolution, ECC detection, scan engine, classification criteria (bootstrap mode), upstream_domains, scoring algorithm (bootstrap mode), project type, phase presentation, manifest schema, and operational notes. Follow that spec exactly for all shared operations.

## Output Language

All user-facing output (messages, tables, prompts, reports) MUST be in Japanese.

## Flow

### Step 1: Path Resolution & ECC Detection

Resolve paths per shared spec. If ECC not found, display the error message from shared spec and stop.

### Step 2: Manifest Check

Read `$MANIFEST_PATH`. If it exists and bootstrap has already been completed (`phases.upstream.installed_at` is set), ask the user to confirm re-execution:

「bootstrap は既に実行済みです。再実行しますか？」

### Step 3: Initial Setup (only if manifest does not exist)

#### 3a: Ask User

Use AskUserQuestion:

**Q0: Project Type** (single-select)

「プロジェクトの種類を選択してください:」

1. Frontend（SPA / SSR / Static サイト）
2. Backend（API / CLI / Worker）
3. Fullstack（Frontend + Backend + Infrastructure + DevOps）
4. Library / Package（ライブラリ / パッケージ）
5. Infrastructure / DevOps
6. Data / ML Pipeline

#### 3b: Initialize Manifest

Create `$MANIFEST_PATH` with the manifest schema from shared spec (version 2). Save:

- Q0 → `project.type`
- `project.tech_stack.languages: []` (empty — set during configure)
- `project.tech_stack.frameworks: []` (empty — set during configure)
- `project.tech_stack.tools: []` (empty — set during configure)
- `project.tech_stack_source: null` (set during configure)

#### 3c: Update CLAUDE.md Tech Stack

If `$PROJECT_ROOT/CLAUDE.md` exists and contains "(TBD" placeholder:

Replace with `(TBD — /ecc-configure で自動設定されます)`

### Step 4: Run Scan Engine (Bootstrap Mode)

Execute scan engine per shared spec. Classify all components using **bootstrap mode**:

1. Match each component's `description` and body content against **upstream_domains** keywords
2. Apply **bootstrap mode scoring** per shared spec
3. **Do NOT apply language/FW -100 exclusion** — tech stack is not yet determined
4. Sort components by score within each phase

### Step 5: Present Recommendations (Phase-based)

Display scored components grouped first by auto-install status, then by Phase (component type):

```markdown
## 🔒 自動インストール（Safety + Common Rules）

以下のコンポーネントは自動的にインストールされます:

| # | Component | Type | Domain | 説明 |
| --- | --- | --- | --- | --- |
| 1 | safety-guard | skill | safety | (description) |
| 2 | common/ | rules | common_rules | 共通コーディング規約 (10 files) |

## Upstream Components

### Phase A: Skills — 上流工程支援

#### ⭐⭐⭐ 強く推薦
| # | Component | Domain | 説明 | 根拠 |
| --- | --- | --- | --- | --- |
| 1 | (name) | (domain) | (description) | (match reason) |

#### ⭐⭐ 推薦
| # | Component | Domain | 説明 | 根拠 |
| --- | --- | --- | --- | --- |

#### ⭐ 任意
...

### Phase B: Agents — 専門レビュアー・ビルダー
(same format per phase, with Domain column)

### Phase C: Rules — コーディング規約
(common/ is auto-installed above. Other rule directories shown here if they match upstream_domains.)

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

Copy approved components (including auto-install components) to destinations per shared spec. Create directories with `mkdir -p` as needed.

MCP components: Read existing `$PROJECT_CLAUDE/settings.json`, add approved servers under `mcpServers` key, write back formatted JSON. Never overwrite other settings.

For MCP servers with `env` field, display:

「⚠️ (server_name) には以下の環境変数の設定が必要です: (env_keys)」
「設定方法: export KEY=value または .env ファイルに追加」

### Step 7: Update Manifest

Record each installed component with: type, name, source, destination, phase ("upstream"), domain, score, reason, installed_at (ISO 8601). Set `phases.upstream.installed_at`. Record `ecc.commit_hash` and `ecc.last_sync`. Add scan entry to `scans[]` with `scan_mode: "bootstrap"`.

### Step 8: Generate Report

Output to `$REPORT_DIR/bootstrap-YYYY-MM-DD.md`:

1. **Scan Summary** — Total scanned, upstream domain match counts
2. **Phase-based Results** — Phase A-E ごとのインストール結果（Domain 列付き）
3. **Coverage Analysis** — Coverage per upstream_domain
4. **Gaps** — Uncovered upstream domains and recommendations
5. **Next Steps** — 以下の内容を出力:

```markdown
## Next Steps

1. **cc-sdd: 要件定義 + steering を実施**
   - `/kiro:steering` — プロジェクト文脈・技術スタックの決定
   - `/kiro:spec-init <feature>` → `/kiro:spec-requirements <feature>`

   ⚠️ `/kiro:steering` で以下を確定してください:
   - 使用言語 (TypeScript, Python 等)
   - フレームワーク (Next.js, NestJS, LangGraph 等)
   - インフラ/ツール (AWS, Docker, Playwright 等)

2. **`/ecc-configure`** を実行
   → `.kiro/steering/tech.md` から技術スタックを自動抽出し、
     実装に必要な rules, skills, agents, commands, MCP をインストールします。

⚠️ 設計（spec-design）、実装（spec-impl）は `/ecc-configure` 後に開始してください。
   ecc-configure が技術スタックに適したコンポーネントをインストールし、
   設計・実装の品質を最大化します。
```
