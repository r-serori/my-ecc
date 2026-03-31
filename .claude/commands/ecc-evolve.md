---
description: "Install continuous improvement components and apply ECC updates."
---

# ECC Evolve — Continuous Improvement + Update Sync

## Prerequisites

Read `docs/ecc-shared-spec.md` for: path resolution, ECC detection, scan engine, classification criteria, classification keywords, scoring algorithm, project type, phase presentation, manifest schema, and operational notes. Follow that spec exactly for all shared operations.

## Output Language

All user-facing output (messages, tables, prompts, reports) MUST be in Japanese.

## Flow

### Step 1: Precondition Check

Read `$MANIFEST_PATH`. Confirm bootstrap and configure are completed (`phases.upstream.installed_at` and `phases.downstream.installed_at` are set). If not, stop with appropriate message directing user to run the missing command first.

### Step 2: Continuous Improvement Component Install (Phase-based)

Execute scan engine per shared spec in **evolve mode**. Classify and filter for continuous improvement components only. Apply scoring algorithm. Sort components by score within each phase.

Display results grouped by Phase (component type) per shared spec Phase Presentation format. Skip empty phases silently (continuous improvement is mostly Skills and Commands — Agents/Rules/MCP phases may be empty).

Per phase, prompt user with selection syntax from shared spec:

「Phase X: (Phase Name) — インストールするコンポーネントを選択してください:」

- 番号指定: `1,2,3,5-8`
- `recommended` — ⭐⭐⭐ + ⭐⭐ を全選択
- `all` — 全てインストール
- `info <番号>` — 詳細を表示
- `skip` — このフェーズをスキップ

Install approved components to destinations per shared spec.

### Step 3: ECC Update Detection

1. Get current ECC commit: `git -C $ECC_ROOT rev-parse HEAD`
2. Compare with manifest `ecc.commit_hash`
3. If different, get changed files: `git -C $ECC_ROOT diff --name-only <old-hash> <new-hash>`
4. Check if changed files affect any component in manifest `installed[]`
5. If yes, display update proposal:

```text
ECC が更新されています（<old-hash> → <new-hash>）

以下のインストール済みコンポーネントが更新されています:
  - <name> (<type>): <what changed>

更新しますか？
```

6. If approved, re-copy updated components from ECC to their destinations.

### Step 4: New Component Notification

If ECC update added new components (files in scan paths that don't match any existing manifest entry):

- Scan new components with the scan engine
- Apply scoring algorithm to new components
- If any match user's tech stack (score > 0), notify:

「新しいコンポーネントが利用可能です:」

Display new components grouped by Phase, with scores and descriptions. Include new MCP servers in the notification scan.

- If new language/framework support was added, also notify

### Step 5: Update Manifest → Generate Report

- Update `ecc.commit_hash` and `ecc.last_sync`
- Set `phases.continuous.installed_at` if continuous improvement components were installed
- Add entries to `installed[]` with phase ("continuous") and score for any newly installed components
- Add scan entry to `scans[]` with `scan_mode: "evolve"`
- Generate report to `$REPORT_DIR/evolve-YYYY-MM-DD.md`
