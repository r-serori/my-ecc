---
description: "Install Tier 2 (implementation) ECC components. Run AFTER cc-sdd design is finalized."
---

# ECC Configure — Tier 2 Installer

## Prerequisites

Read `docs/ecc-shared-spec.md` for: path resolution, ECC detection, scan engine, classification criteria, manifest schema, and operational notes. Follow that spec exactly for all shared operations.

## Output Language

All user-facing output (messages, tables, prompts, reports) MUST be in Japanese.

## Flow

### Step 1: Precondition Check

1. Read `$MANIFEST_PATH`. If bootstrap not completed (`tiers.tier1.installed_at` is null), stop:
   「先に `/ecc-bootstrap` を実行してください。」

2. Check for cc-sdd artifacts (`.kiro/` directory or design-related files). If missing, warn but do not block:
   「cc-sdd の設計フェーズがまだ完了していないようです。続行しますか？」

### Step 2: Run Scan Engine

Execute scan engine per shared spec. Classify components and filter for **Tier 2 only**. Apply tech stack filter **strictly** based on manifest `tech_stack`.

### Step 3: Diff Display

Compare scan results against manifest `installed[]`:

| Status | Meaning |
|---|---|
| **SKIP** | Already installed (same tier) |
| **INSTALL** | New component, not yet installed |
| **ALREADY INSTALLED** | Installed during bootstrap, also matches Tier 2 |

Display the diff table to user, grouped by domain.

### Step 4: User Approval → Install → Update Manifest → Generate Report

Same flow as bootstrap Steps 5-8:
- Present recommendations and ask for approval
- Copy approved components to destinations
- Update manifest: set `tiers.tier2.installed_at`, add entries to `installed[]`, add scan entry
- Generate report to `$REPORT_DIR/configure-YYYY-MM-DD.md`
