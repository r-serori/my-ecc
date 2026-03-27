---
description: "Install Tier 2 (implementation) ECC components. Run AFTER cc-sdd design is finalized."
---

# ECC Configure — Tier 2 Installer

## Prerequisites

Read `docs/ecc-shared-spec.md` for: path resolution, ECC detection, scan engine, classification criteria, classification keywords, scoring algorithm, project type, phase presentation, manifest schema, and operational notes. Follow that spec exactly for all shared operations.

## Output Language

All user-facing output (messages, tables, prompts, reports) MUST be in Japanese.

## Flow

### Step 1: Precondition Check

1. Read `$MANIFEST_PATH`. If bootstrap not completed (`tiers.tier1.installed_at` is null), stop:
   「先に `/ecc-bootstrap` を実行してください。」

2. Check for cc-sdd artifacts (`.kiro/` directory or design-related files). If missing, warn but do not block:
   「cc-sdd の設計フェーズがまだ完了していないようです。続行しますか？」

### Step 2: Run Scan Engine

Execute scan engine per shared spec. Classify components and filter for **Tier 2 only**. Apply scoring algorithm per shared spec **strictly** based on manifest `tech_stack` and `project.type`. Sort components by score within each phase.

### Step 3: Phase-based Diff Display

Compare scan results against manifest `installed[]`. Display results grouped by Phase (component type) per shared spec Phase Presentation format.

Each component shows a status alongside its score:

| Status | Meaning |
| --- | --- |
| **INSTALL** | New component, not yet installed |
| **SKIP** | Already installed (same tier) |
| **ALREADY INSTALLED** | Installed during bootstrap, also matches Tier 2 |

```markdown
### Phase A: Skills — 設計知識・パターン

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
(same format)

### Phase D: Commands — ワークフロー
(same format)

### Phase E: MCP Servers — 外部ツール連携
(same format, ⚠️ mark servers requiring API keys)
```

Skip empty phases silently.

### Step 4: User Approval → Install → Update Manifest → Generate Report

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
- Update manifest: set `tiers.tier2.installed_at`, add entries to `installed[]` with score, add scan entry to `scans[]`
- Generate report to `$REPORT_DIR/configure-YYYY-MM-DD.md`
