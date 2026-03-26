---
description: "Install Tier 3 (continuous improvement) components and apply ECC updates."
---

# ECC Evolve — Tier 3 + Update Sync

## Prerequisites

Read `docs/ecc-shared-spec.md` for: path resolution, ECC detection, scan engine, classification criteria, manifest schema, and operational notes. Follow that spec exactly for all shared operations.

## Output Language

All user-facing output (messages, tables, prompts, reports) MUST be in Japanese.

## Flow

### Step 1: Precondition Check

Read `$MANIFEST_PATH`. Confirm bootstrap and configure are completed (`tiers.tier1.installed_at` and `tiers.tier2.installed_at` are set). If not, stop with appropriate message directing user to run the missing command first.

### Step 2: Tier 3 Component Install

Execute scan engine per shared spec. Classify and filter for **Tier 3 only**. Follow the same scan → recommend → approve → install → update manifest flow as bootstrap.

### Step 3: ECC Update Detection

1. Get current ECC commit: `git -C $ECC_ROOT rev-parse HEAD`
2. Compare with manifest `ecc.commit_hash`
3. If different, get changed files: `git -C $ECC_ROOT diff --name-only <old-hash> <new-hash>`
4. Check if changed files affect any component in manifest `installed[]`
5. If yes, display update proposal:

```
ECC が更新されています（<old-hash> → <new-hash>）

以下のインストール済みコンポーネントが更新されています:
  - <name> (<type>): <what changed>

更新しますか？
```

6. If approved, re-copy updated components from ECC to their destinations.

### Step 4: New Component Notification

If ECC update added new components (files in scan paths that don't match any existing manifest entry):

- Scan new components with the scan engine
- If any match user's tech stack, notify:
  「新しいコンポーネントが利用可能です:」followed by the list
- If new language/framework support was added, also notify

### Step 5: Update Manifest → Generate Report

- Update `ecc.commit_hash` and `ecc.last_sync`
- Set `tiers.tier3.installed_at` if Tier 3 components were installed
- Add scan entry to `scans[]`
- Generate report to `$REPORT_DIR/evolve-YYYY-MM-DD.md`
