---
description: "Install Tier 0 (safety) + Tier 1 (design knowledge) ECC components. Run BEFORE cc-sdd."
---

# ECC Bootstrap — Tier 0 + Tier 1 Installer

## Prerequisites

Read `docs/ecc-shared-spec.md` for: path resolution, ECC detection, scan engine, classification criteria, manifest schema, and operational notes. Follow that spec exactly for all shared operations.

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

Scan ECC to dynamically build available languages and frameworks:

- `$ECC_ROOT/rules/` subdirectory names → available **languages** list
  - Example: `common/`, `typescript/`, `python/` → TypeScript, Python
- `$ECC_ROOT/skills/*/SKILL.md` descriptions → available **frameworks/libraries** list
  - Extract framework names from descriptions (Next.js, Django, Flask, Docker, etc.)
- `$ECC_ROOT/agents/*.md` names → language-specific **agents** list

#### 3b: Ask User

Use AskUserQuestion for each:

**Q1: Languages** (multi-select from scan results)

「使用する言語を選択してください（カンマ区切りで入力）:」followed by the discovered language list.

**Q2: Frameworks/Libraries/Tools** (multi-select, filtered by Q1 + language-agnostic tools)

「使用するフレームワーク/ライブラリ/ツールを選択してください（カンマ区切りで入力）:」followed by relevant options based on Q1 answers.

#### 3c: Initialize Manifest

Create `$MANIFEST_PATH` with the manifest schema from shared spec. Save user answers to `project.tech_stack`.

### Step 4: Run Scan Engine

Execute scan engine per shared spec. Classify all components. Filter results for **Tier 0 and Tier 1 only**. Apply tech stack filter.

### Step 5: Present Recommendations

Display classified components grouped by knowledge domain:

```markdown
## Tier 0: Safety

| Action | Component | Type | 説明 |
| --- | --- | --- | --- |
| ✅ INSTALL | <name> | <type> | <description> |

## Tier 1: Design Knowledge

### <Domain Name>
| Action | Component | Type | 説明 |
| --- | --- | --- | --- |
| ✅ INSTALL | <name> | <type> | <description> |

## Coverage Analysis
| ドメイン | 状況 | カバーコンポーネント |
| --- | --- | --- |
| Architecture | ✅ COVERED | ... |
| API Design | ⚠️ PARTIAL | ... |
```

Ask user: 「この構成でインストールしますか？ 除外/追加したいものがあれば指定してください。」

### Step 6: Install

Copy approved components to destinations per shared spec. Create directories with `mkdir -p` as needed.

### Step 7: Update Manifest

Record each installed component with: type, name, source, destination, tier, domain, reason, installed_at (ISO 8601). Set `tiers.tier0.installed_at` and `tiers.tier1.installed_at`. Record `ecc.commit_hash` and `ecc.last_sync`. Add scan entry to `scans[]`.

### Step 8: Generate Report

Output to `$REPORT_DIR/bootstrap-YYYY-MM-DD.md`:

1. **Scan Summary** — Total scanned, counts per tier
2. **Classification Results** — All components table (INSTALLED / EXCLUDED / SKIPPED)
3. **Coverage Analysis** — Coverage per knowledge domain
4. **Gaps** — Uncovered domains and recommendations
5. **Next Steps** — Instructions to start cc-sdd
