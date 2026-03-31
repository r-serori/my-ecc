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

**Q3: Response language**
「Claude の応答言語を選択してください:」

Options:

- ja (日本語)
- en（英語）
- その他（自由入力）

Q3 is used for:
- Step 2: `--lang` parameter for cc-sdd
- Step 4: `{{LANGUAGE}}` placeholder replacement

### Step 2: Install cc-sdd

Check if `.kiro/` directory exists.

If exists:
  「cc-sdd は既にインストール済みのようです（.kiro/ が存在）。再インストールしますか？」
  If no: skip to Step 3.

If not exists or user confirms:

  **Pre-install guard:**
  If `$PROJECT_ROOT/CLAUDE.md` exists:
    Copy to `$PROJECT_ROOT/CLAUDE.md.pre-ccsdd-bak`.
    「既存の CLAUDE.md をバックアップしました → CLAUDE.md.pre-ccsdd-bak」

  Run: `npx cc-sdd@latest --claude-agent --lang <Q3 answer>`

  **Post-install cleanup:**
  If `$PROJECT_ROOT/CLAUDE.md` exists:
    Delete `$PROJECT_ROOT/CLAUDE.md`.
    「cc-sdd が生成した CLAUDE.md を削除しました（ECC テンプレート版を Step 4 で生成します）」

### Step 3: Settings Template

Read `$TEMPLATES_DIR/settings.json` (resolve via shared spec).

If `$PROJECT_CLAUDE/settings.json` does NOT exist:
  Copy template to `$PROJECT_CLAUDE/settings.json`.
  「✅ settings.json を作成しました（安全方針テンプレート）」

If exists:
  「settings.json が既に存在します。テンプレートの安全方針をマージしますか？」
  If yes: merge deny list (union), preserve existing allow/ask entries.

> **Note:** パッケージマネージャーの権限（`allow` リスト）は `/ecc-configure` が技術スタック確定後に自動追加します。

### Step 4: Generate CLAUDE.md

Read `$TEMPLATES_DIR/CLAUDE.md.template`.

Replace placeholders:

- `{{PROJECT_NAME}}` → Q1 answer
- `{{PROJECT_OVERVIEW}}` → Q2 answer
- `{{LANGUAGE}}` → Q3 answer (言語名: "Japanese", "English", etc.)

If `$PROJECT_ROOT/CLAUDE.md` exists AND `$PROJECT_ROOT/CLAUDE.md.pre-ccsdd-bak` does NOT exist:
  Copy to `$PROJECT_ROOT/CLAUDE.md.bak`.
  「既存の CLAUDE.md を CLAUDE.md.bak にバックアップしました。」

Write generated content to `$PROJECT_ROOT/CLAUDE.md`.

If `$PROJECT_ROOT/CLAUDE.md.pre-ccsdd-bak` exists:
  「ℹ️ cc-sdd 実行前の CLAUDE.md バックアップがあります（CLAUDE.md.pre-ccsdd-bak）。」
  「必要に応じて、プロジェクト固有の設定を新しい CLAUDE.md に手動でマージしてください。」

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
  Display: 「✅ ECC 検出: (path) (version)」

If not found:
  Display setup instructions from shared spec.
  Do NOT stop — /ecc-init can complete without ECC.
  Display: 「⚠️ ECC が見つかりません。/ecc-bootstrap の前にセットアップしてください。」

### Step 7: Summary

Display:

```text
✅ プロジェクト初期化完了

  セットアップ内容:
    - プロジェクト: <Q1>
    - cc-sdd: [インストール済み / スキップ]
    - settings.json: [作成 / マージ / スキップ]
    - CLAUDE.md: 生成済み（XX行）
    - .gitignore: [更新 / 作成 / スキップ]
    - ECC: [検出 (<version>) / 未検出]

  次のステップ:
    1. /ecc-bootstrap — 上流工程支援コンポーネントのインストール
    2. cc-sdd 要件定義（/kiro:steering → /kiro:spec-requirements）
    3. /ecc-configure — 技術スタック自動抽出 + 実装コンポーネント

    ⚠️ 設計、実装は /ecc-configure 後に開始してください。
```
