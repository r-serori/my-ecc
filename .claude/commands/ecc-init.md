---
description: "Initialize project for ECC + cc-sdd workflow. Run this first."
---

# ECC Init — Project Setup

## Prerequisites

Read `docs/ecc-shared-spec.md` for: path resolution.

## Output Language

All user-facing output (messages, prompts) MUST be in Japanese.

## Flow

### Step 1: Project Information

Use AskUserQuestion for each:

**Q1: Project name**
「プロジェクト名を入力してください:」

**Q2: Project overview** (1-2 sentences)
「プロジェクトの概要を簡潔に記述してください（1-2文）:」

**Q3: Tech stack** (languages + frameworks)
「主要な技術スタックを入力してください（例: TypeScript, Next.js, Python, FastAPI）:」

**Q4: Package manager**
「使用するパッケージマネージャーを選択してください（npm / pnpm / yarn / bun / uv）:」

### Step 2: Install cc-sdd

Check if `.kiro/` directory exists.

If exists:
  「cc-sdd は既にインストール済みのようです（.kiro/ が存在）。再インストールしますか？」
  If no: skip

If not exists or user confirms:
  Run: `npx cc-sdd@latest --claude-agent --lang ja`

### Step 3: Settings Template

Read `$TEMPLATES_DIR/settings.json` (resolve via shared spec).

If `$PROJECT_CLAUDE/settings.json` does NOT exist:
  Copy template to `$PROJECT_CLAUDE/settings.json`.
  Add package manager permissions based on Q4 answer to the `allow` list:
    - pnpm → `"Bash(pnpm *)"`, `"Bash(npx *)"`
    - npm → `"Bash(npm *)"`, `"Bash(npx *)"`
    - yarn → `"Bash(yarn *)"`
    - bun → `"Bash(bun *)"`, `"Bash(bunx *)"`
    - uv → `"Bash(uv *)"`, `"Bash(python *)"`

If exists:
  「settings.json が既に存在します。テンプレートの安全方針をマージしますか？」
  If yes: merge deny list (union), preserve existing allow/ask entries.

### Step 4: Generate CLAUDE.md

Read `$TEMPLATES_DIR/CLAUDE.md.template`.

Replace placeholders:
  - `{{PROJECT_NAME}}` → Q1 answer
  - `{{PROJECT_OVERVIEW}}` → Q2 answer
  - `{{TECH_STACK}}` → Q3 answer

If `$PROJECT_ROOT/CLAUDE.md` exists:
  「CLAUDE.md が既に存在します。上書きしますか？（既存の内容は CLAUDE.md.bak にバックアップされます）」
  If yes: copy existing to `CLAUDE.md.bak`, then write new.

Write generated content to `$PROJECT_ROOT/CLAUDE.md`.
Verify line count < 200. If exceeds, warn user.

### Step 5: Update .gitignore

Read `$TEMPLATES_DIR/gitignore.append`.

If `$PROJECT_ROOT/.gitignore` exists:
  Append only lines not already present.
If not:
  Create new `.gitignore` with template content.

### Step 6: ECC Path Check

Resolve ECC_ROOT per shared spec (priority: env var → manifest → default).

If found:
  Get version: `git -C $ECC_ROOT describe --tags 2>/dev/null || git -C $ECC_ROOT rev-parse --short HEAD`
  Display: 「✅ ECC 検出: <path> (<version>)」

If not found:
  Display setup instructions from shared spec.
  Do NOT stop — /ecc-init can complete without ECC.
  Display: 「⚠️ ECC が見つかりません。/ecc-bootstrap の前にセットアップしてください。」

### Step 7: Summary

Display:

```
✅ プロジェクト初期化完了

  セットアップ内容:
    - プロジェクト: <Q1>
    - cc-sdd: [インストール済み / スキップ]
    - settings.json: [作成 / マージ / スキップ]
    - CLAUDE.md: 生成済み（XX行）
    - .gitignore: [更新 / 作成 / スキップ]
    - ECC: [検出 (<version>) / 未検出]

  次のステップ:
    1. /ecc-bootstrap — 安全方針 + 設計知識のインストール
    2. /kiro:steering — プロジェクト文脈の収集
```
