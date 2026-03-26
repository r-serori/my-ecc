# Claude Code セットアップガイド — SDD × ECC ワークフロー

> 本ドキュメントは、SDD（Spec Driven Development / cc-sdd）と ECC（Everything Claude Code）を組み合わせて開発を進める際の、Claude Code 設定の最適なタイミング・手順・推奨構成をまとめたものである。

---

## 目次

1. [前提: 技術スタックとアーキテクチャ](#1-前提-技術スタックとアーキテクチャ)
2. [ECC ベストプラクティス](#2-ecc-ベストプラクティス)
3. [cc-sdd ワークフロー（AI-DLC）](#3-cc-sdd-ワークフローai-dlc)
4. [SDD × Claude Code 設定チューニングの最適フロー](#4-sdd--claude-code-設定チューニングの最適フロー)
5. [settings.json 設定ガイド](#5-settingsjson-設定ガイド)
6. [Git 操作の許可/禁止ベストプラクティス](#6-git-操作の許可禁止ベストプラクティス)
7. [Hooks との連携](#7-hooks-との連携)
8. [セキュリティガイドライン](#8-セキュリティガイドライン)
9. [cc-sdd と ECC の役割分担](#9-cc-sdd-と-ecc-の役割分担)
10. [推奨 settings.json（テンプレート）](#10-推奨-settingsjsonテンプレート)
11. [ECC ディレクトリ構造ガイド](#11-ecc-ディレクトリ構造ガイド)

---

## 1. 前提: 技術スタックとアーキテクチャ

### 開発思想

| 思想                           | ツール                 |
| ------------------------------ | ---------------------- |
| SDD（Spec Driven Development） | cc-sdd                 |
| TDD（Test Driven Development） | ECC の tdd-guide agent |

### 技術スタック

| レイヤー                   | 技術                                                                                            |
| -------------------------- | ----------------------------------------------------------------------------------------------- |
| **パッケージマネージャー** | pnpm（Node.js）、uv（Python）                                                                   |
| **Frontend**               | Next.js v16、TypeScript、TailwindCSS v4、shadcn、TanStack Query                                 |
| **Backend**                | NestJS（TypeScript）、Python（LangChain, LangGraph, LangSmith, Ragas, FireCrawl, Tavily, Jina） |
| **Backend 目的**           | カスタム Deep Research AI Agent の構築                                                          |
| **Infra**                  | AWS（CDK, Lambda, DynamoDB, S3, API Gateway, EventBridge, CloudWatch）                          |

### 重要な方針

- 全スタック分の skills / rules は作成しない（Context Window の圧迫を回避）
- 必要最小限から始め、段階的に追加する

---

## 2. ECC ベストプラクティス

### Context Window 管理が最重要

- 200k のコンテキストウィンドウは、ツールを有効にしすぎると **約70k** まで縮小する
- MCP は 20-30個設定しても **5-10個だけ有効化**（プロジェクトごと）
- アクティブツール合計は **80個以下** に抑える
- 不要な rules / skills / agents を入れすぎない

### 推奨インストールプロファイル

| プロファイル  | 用途                                                          |
| ------------- | ------------------------------------------------------------- |
| **core**      | 最小構成（共通rules + 基本agents + 基本commands）             |
| **developer** | 一般開発者向け（core + 言語固有 + DB + オーケストレーション） |
| **full**      | 全モジュール（上級者/実験向け）                               |

本プロジェクトでは **developer プロファイル + TypeScript + Python ルール** が適切。

### ECC コンポーネント概要

| コンポーネント | 数量          | 主な内容                                                               |
| -------------- | ------------- | ---------------------------------------------------------------------- |
| Agents         | 13個          | planner, architect, tdd-guide, code-reviewer, security-reviewer 等     |
| Skills         | 43個以上      | コーディング標準、バックエンド/フロントエンドパターン、継続的学習v2 等 |
| Commands       | 31個以上      | /tdd, /plan, /e2e, /code-review, /build-fix, /refactor-clean 等        |
| Rules          | 4カテゴリ     | common（必須）、typescript、python、golang                             |
| Hooks          | 3プロファイル | minimal, standard, strict                                              |

### ルール構造

```
rules/
├── common/       （言語非依存 — 必須）
├── typescript/   （TypeScript/JavaScript固有）
├── python/       （Python固有）
└── golang/       （Go固有 — 本プロジェクトでは不要）
```

---

## 3. cc-sdd ワークフロー（AI-DLC）

### 概要

cc-sdd は「仕様駆動開発」を AI エージェント上で実現するツール。
**「1コマンドで、要件定義 → 設計 → タスク分解 → 実装」** を構造化されたフローで進める。

### インストール

```bash
cd your-project
npx cc-sdd@latest --claude-agent --lang ja
```

| フラグ           | 説明                                                     |
| ---------------- | -------------------------------------------------------- |
| `--claude`       | 標準モード（11コマンド）                                 |
| `--claude-agent` | サブエージェントモード（12コマンド + 9サブエージェント） |
| `--lang ja`      | 日本語出力                                               |
| `--dry-run`      | 適用前のプレビュー                                       |

### 8フェーズのライフサイクル

| Phase               | コマンド                                      | 生成物                                  | 説明                                       |
| ------------------- | --------------------------------------------- | --------------------------------------- | ------------------------------------------ |
| 1. Steering         | `/kiro:steering`                              | `.kiro/steering/*.md`                   | プロジェクト文脈・規約・ドメイン知識の収集 |
| 2. Spec Init        | `/kiro:spec-init <feature>`                   | `.kiro/specs/<feature>/`                | フィーチャーワークスペース作成             |
| 3. Requirements     | `/kiro:spec-requirements <feature>`           | `requirements.md`                       | EARS形式の要件定義                         |
| 4. Design           | `/kiro:spec-design <feature>`                 | `research.md`, `design.md`              | アーキテクチャ設計（Mermaid図含む）        |
| 5. Tasks            | `/kiro:spec-tasks <feature>`                  | `tasks.md`                              | 実装タスク分解（P0/P1の並列度ラベル付き）  |
| 6. Implementation   | `/kiro:spec-impl <feature> <task-ids>`        | コード                                  | 仕様に基づく実装                           |
| 7. Validate（任意） | `/kiro:validate-gap`, `/kiro:validate-design` | `gap-report.md`, `design-validation.md` | ギャップ分析、設計検証                     |
| 8. Status           | `/kiro:spec-status <feature>`                 | —                                       | 進捗・承認状況の確認                       |

### ワークフローパターン

**Greenfield（新規開発）:**

```
spec-init → spec-requirements → spec-design → spec-tasks → spec-impl
```

**Brownfield（既存改修）:**

```
steering → spec-init → validate-gap → spec-design → validate-design → spec-tasks → spec-impl
```

**高速モード:**

```
/kiro:spec-quick <feature>    # Phase 2-5 を一括実行（各フェーズで承認ゲートあり）
```

### レビューゲート

各フェーズは人間のレビューのために **自動で一時停止** する。
`-y` フラグまたは `--auto` で自動承認も可能だが、本番作業では手動承認を推奨。

### カスタマイズポイント

| カスタマイズ対象 | 場所                                   | 説明                         |
| ---------------- | -------------------------------------- | ---------------------------- |
| テンプレート     | `{{KIRO_DIR}}/settings/templates/*.md` | 各フェーズの文書構造を定義   |
| ルール           | `{{KIRO_DIR}}/settings/rules/`         | AI生成の原則・判断基準       |
| サブエージェント | `.claude/agents/kiro/*.md`             | 組織固有のヒューリスティクス |
| コマンド         | `.claude/commands/kiro/*.md`           | 実行条件・ガードレール       |

---

## 4. SDD × Claude Code 設定チューニングの最適フロー

### 核心的な結論

> **settings.json は Phase 0（最初）に設定する。**
> **CLAUDE.md・rules・agents・hooks は Phase 5（設計確定後）に本格設定する。**

理由: settings.json は「安全方針」であり仕様に依存しない。一方、rules・agents 等は設計内容に依存するため、cc-sdd の設計フェーズが完了してから設定するのが合理的。

### 全体フロー図

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 cc-sdd フェーズ              │ Claude Code 設定タイミング
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                              │
 ■ Phase 0: Setup             │ ★ 設定A: 最小構成
   cc-sdd install             │   ・settings.json（安全方針 — 許可/禁止）
   ECC common rules           │   ・cc-sdd インストール
                              │   ・共通 rules のみ
                              │   ・CLAUDE.md（概要のみ）
                              │   ・環境変数設定
                              │
 ■ Phase 1: Steering          │   （設定変更なし）
   プロジェクト文脈収集        │   cc-sdd が .kiro/steering/ を生成
                              │
 ■ Phase 2: Spec Init         │   （設定変更なし）
                              │
 ■ Phase 3: Requirements      │   （設定変更なし）
   要件定義                   │   cc-sdd が requirements.md を生成
                              │
 ■ Phase 4: Design            │   （設定変更なし）
   アーキテクチャ設計          │   cc-sdd が design.md を生成
                              │
 ■ Phase 5: Tasks             │
   タスク分解                 │   cc-sdd が tasks.md を生成
                              │
 ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─  │ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─
   ここで設計が確定 ✓         │
                              │ ★ 設定B: 本格構成
 ■ Phase 6: Validate          │   ・言語固有 rules（TS, Python）
   ギャップ検証               │   ・CLAUDE.md 充実
                              │   ・agents, hooks, commands
                              │
 ■ Phase 7: Implementation    │   （設定B で実装開始）
   TDD 実装                   │   ECC の /tdd, /code-review 活用
                              │
 ■ Phase 8: Status            │ ★ 設定C: 継続的改善
   進捗確認                   │   ・/learn で skills 追加
                              │   ・CLAUDE.md 更新
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### 設定A: Phase 0（今やるべきこと）

| やること                | 詳細                                                           |
| ----------------------- | -------------------------------------------------------------- |
| **settings.json**       | 安全方針（許可/禁止ルール）を設定                              |
| **cc-sdd インストール** | `npx cc-sdd@latest --claude-agent --lang ja`                   |
| **共通 rules**          | `cp -r everything-claude-code/rules/common/* ~/.claude/rules/` |
| **環境変数**            | `CLAUDE_PACKAGE_MANAGER=pnpm`                                  |
| **CLAUDE.md**           | プロジェクト概要・技術スタック・開発手法のみ                   |

### 設定B: Phase 5 完了後（設計確定時）

| 設計で確定すること      | それに依存する Claude Code 設定             |
| ----------------------- | ------------------------------------------- |
| ディレクトリ構造        | CLAUDE.md の Architecture セクション        |
| API設計方針             | rules（命名規則、レスポンス形式）           |
| テスト戦略              | hooks（自動テスト実行、カバレッジチェック） |
| フロント/バック分離方針 | 言語固有 rules の選定                       |
| AWS構成の詳細           | カスタム agents（CDK reviewer等）           |

やること:

1. `rules/typescript/` と `rules/python/` をインストール
2. CLAUDE.md を design.md の内容に基づいて充実
3. agents を有効化（tdd-guide, code-reviewer, security-reviewer）
4. hooks を設定（型チェック、フォーマッター、push前レビュー）

### 設定C: Phase 7 以降（継続的改善）

- `/learn` でセッションからパターンを抽出 → skills 化
- CLAUDE.md に発見した制約やパターンを追記
- プロジェクト固有 rules を追加

---

## 5. settings.json 設定ガイド

### 設定スコープ

| スコープ    | ファイル                      | 対象                     | チーム共有       |
| ----------- | ----------------------------- | ------------------------ | ---------------- |
| **Managed** | OS/サーバー管理               | 全ユーザー               | Yes（IT配布）    |
| **User**    | `~/.claude/settings.json`     | 自分の全プロジェクト     | No               |
| **Project** | `.claude/settings.json`       | リポジトリ全協力者       | Yes（git管理）   |
| **Local**   | `.claude/settings.local.json` | 自分、このリポジトリのみ | No（gitignored） |

### 設定の優先順位

```
Managed（最高） > CLI引数 > Local > Project > User（最低）
```

**deny はどのレベルでも最優先** — 上位で deny されたものは下位で allow できない。

### Permission の評価順序

```
deny → ask → allow
```

最初にマッチしたルールが適用される。deny が常に最優先。

### 設定タイミング

| スコープ    | いつ設定するか        | 何を設定するか                  |
| ----------- | --------------------- | ------------------------------- |
| **User**    | Phase 0（最初）       | 全プロジェクト共通の安全方針    |
| **Project** | Phase 5（設計確定後） | プロジェクト固有の追加許可/禁止 |
| **Local**   | 必要に応じて          | 個人の実験的設定                |

### Permission ルール構文

| ルール                         | 効果                                             |
| ------------------------------ | ------------------------------------------------ |
| `Bash`                         | 全 Bash コマンドにマッチ                         |
| `Bash(npm run *)`              | `npm run` で始まるコマンドにマッチ               |
| `Bash(git * main)`             | `git checkout main`, `git merge main` 等にマッチ |
| `Read(./.env)`                 | .env ファイルの読み取りにマッチ                  |
| `Edit(/src/**/*.ts)`           | src 配下の全 .ts ファイル編集にマッチ            |
| `WebFetch(domain:example.com)` | 特定ドメインへのフェッチにマッチ                 |

**ワイルドカードの注意点:**

- `Bash(ls *)` — `ls -la` にマッチするが `lsof` にはマッチしない（スペース境界）
- `Bash(ls*)` — `ls -la` にも `lsof` にもマッチする
- `*` は単一ディレクトリ、`**` は再帰的にマッチ（Read/Edit の場合）

**Windows パスの注意:**

- パスは POSIX 形式に正規化される: `C:\Users\alice` → `/c/Users/alice`
- 全ドライブ横断: `//**/.env`

### defaultMode オプション

| モード              | 説明                                             |
| ------------------- | ------------------------------------------------ |
| `default`           | 標準: 各ツール初回使用時に確認                   |
| `acceptEdits`       | ファイル編集を自動承認                           |
| `plan`              | 分析のみ、変更不可                               |
| `auto`              | 安全性チェック付き自動承認（リサーチプレビュー） |
| `dontAsk`           | 事前許可済みツール以外は自動拒否                 |
| `bypassPermissions` | 確認をスキップ（隔離環境専用）                   |

---

## 6. Git 操作の許可/禁止ベストプラクティス

### 3段階分類

| 分類                    | Git 操作                                                                                                                                                       | 理由                                                     |
| ----------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------- |
| **allow（自動許可）**   | `status`, `diff`, `log`, `branch`, `checkout`, `switch`, `add`, `commit`, `stash`, `merge`, `rebase`, `fetch`, `remote`, `tag`, `cherry-pick`, `blame`, `show` | 全てローカル操作。リモートに影響しない。ロールバック可能 |
| **ask（確認を求める）** | `push`, `push *`                                                                                                                                               | リモートに影響する唯一の通常操作                         |
| **deny（完全禁止）**    | `push --force`, `push -f`, `reset --hard`, `clean -fd`, `clean -f`, `* --no-verify`                                                                            | 不可逆またはフック回避。取り返しがつかない               |

### 判断根拠

#### git commit → allow でよい理由

- ローカル操作であり、`git reset` で容易にやり直せる
- pre-commit / commit-msg hooks が品質ゲートとして機能する
- ECC の `block-no-verify` フックが `--no-verify` での回避を防止する

#### git push → ask であるべき理由

- リモートに変更を送信する唯一の操作 → 影響範囲がローカル外に出る
- ECC の hooks も push 前にレビューリマインダーを出す設計
- ただし毎回ブロックするほど危険ではない → ask（確認1クリック）で十分

#### git push --force → deny であるべき理由

- リモートの履歴を上書きする不可逆操作
- チームメンバーの作業を破壊する可能性がある
- 必要な場合は手動で実行すべき

#### git reset --hard → deny であるべき理由

- ローカルの未コミット変更を全て破棄する不可逆操作
- Claude Code が意図せず実行するリスクを排除する

---

## 7. Hooks との連携

### Hooks の基本構造

| フック種別      | タイミング    | できること                                    |
| --------------- | ------------- | --------------------------------------------- |
| **PreToolUse**  | ツール実行前  | ブロック（exit code 2）、警告（stderr）、許可 |
| **PostToolUse** | ツール実行後  | 分析（ブロック不可）                          |
| **Stop**        | Claude 応答後 | 最終検証                                      |

### Permissions と Hooks の相互作用

```
ツール呼び出し
    │
    ▼
[deny ルール評価] ── マッチ → ブロック（hooks まで到達しない）
    │ マッチしない
    ▼
[PreToolUse hooks] ── exit code 2 → ブロック（allow ルールより優先）
    │ 通過
    ▼
[ask ルール評価] ── マッチ → 確認ダイアログ
    │ マッチしない
    ▼
[allow ルール評価] ── マッチ → 自動許可
    │ マッチしない
    ▼
[デフォルト動作] → ツール種別に応じた確認
```

**重要なポイント:**

- **deny は hooks より優先** — deny されたツールは hooks すら実行されない
- **hooks の exit code 2 は allow より優先** — allow されたツールでも hooks がブロックできる
- **最も柔軟な戦略**: allow で広く許可 → hooks で細かい条件チェック

### ECC Hooks プロファイル

| プロファイル | 説明                                 |
| ------------ | ------------------------------------ |
| `minimal`    | 必須のライフサイクル・安全フックのみ |
| `standard`   | バランスの取れた品質＋安全（推奨）   |
| `strict`     | 追加リマインダー・厳格なガードレール |

```bash
# プロファイル設定
export ECC_HOOK_PROFILE=standard

# 特定フックの無効化
export ECC_DISABLED_HOOKS="pre:bash:tmux-reminder,post:edit:typecheck"
```

### 動作例

```
例1: git commit --no-verify を実行しようとした場合

  1. permissions: "Bash(* --no-verify)" が deny にマッチ
  2. → 即座にブロック（hooks まで到達しない）

例2: git push を実行しようとした場合

  1. permissions: deny にマッチしない
  2. PreToolUse hooks: (ECC の push レビューリマインダー表示)
  3. permissions: "Bash(git push *)" が ask にマッチ → 確認ダイアログ
  4. ユーザーが承認 → 実行

例3: pnpm test を実行しようとした場合

  1. permissions: deny にマッチしない
  2. PreToolUse hooks: 通過
  3. permissions: "Bash(pnpm *)" が allow にマッチ → 自動許可
```

---

## 8. セキュリティガイドライン

### 必ず deny すべきパターン

| カテゴリ               | パターン                                                                                                                                                   | 理由                                   |
| ---------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------- |
| **破壊的ファイル操作** | `rm -rf /*`, `rm -rf ~*`, `rm -rf *`                                                                                                                       | システム/ホーム/プロジェクト全体の削除 |
| **AWS 破壊操作**       | `aws iam *`, `aws sts *`, `aws s3 rm *`, `aws s3 rb *`, `aws dynamodb delete-table *`, `aws lambda delete-function *`, `aws cloudformation delete-stack *` | 認証情報操作・リソース削除             |
| **パイプ実行**         | `curl * \| bash`, `curl * \| sh`, `wget * \| bash`                                                                                                         | 任意コード実行                         |
| **ネットワーク**       | `ssh *`, `scp *`, `nc *`                                                                                                                                   | 認証情報漏洩・ファイル持ち出し         |
| **Git 破壊**           | `git push * --force`, `git reset --hard *`, `git clean -f *`                                                                                               | 不可逆操作                             |
| **フック回避**         | `* --no-verify`, `* --dangerously-skip-permissions`                                                                                                        | 安全機構のバイパス                     |
| **機密ファイル**       | `.env`, `.env.*`, `~/.ssh/**`, `~/.aws/**`                                                                                                                 | 認証情報の読み取り                     |

### ECC AgentShield によるセキュリティ監査

```bash
npx ecc-agentshield scan       # スキャンのみ
npx ecc-agentshield scan --fix # 自動修正付き
npx ecc-agentshield init       # 安全なベースライン生成
```

スキャン対象: CLAUDE.md, settings.json, mcp.json, hooks/, agents/

### セキュリティ最小基準チェックリスト

- [ ] エージェント用アイデンティティを個人アカウントと分離
- [ ] 短期間のスコープ付きクレデンシャルを使用
- [ ] 信頼されていない作業はコンテナ/VM で実行
- [ ] アウトバウンドネットワークをデフォルトで拒否
- [ ] 機密パスからの読み取りを制限
- [ ] ツール呼び出し・承認・ネットワーク試行をログ
- [ ] skills, hooks, MCP 設定をサプライチェーン成果物として監査

---

## 9. cc-sdd と ECC の役割分担

### 機能の重複を避ける

| 機能             | cc-sdd が担当             | ECC が担当                                     |
| ---------------- | ------------------------- | ---------------------------------------------- |
| 要件定義         | `/kiro:spec-requirements` | —                                              |
| 設計             | `/kiro:spec-design`       | —                                              |
| タスク分解       | `/kiro:spec-tasks`        | —                                              |
| 実装計画         | `/kiro:spec-impl`         | `/plan`（補助的に）                            |
| TDD              | —                         | `/tdd`, tdd-guide agent                        |
| コードレビュー   | —                         | `/code-review`, code-reviewer agent            |
| セキュリティ     | —                         | security-reviewer agent                        |
| コーディング規約 | —                         | rules/common + rules/typescript + rules/python |
| Git 運用         | —                         | git-workflow rule, hooks                       |

### 思想の整理

```
cc-sdd  = 「何を作るか」を決める（Spec 層）
ECC     = 「どう作るか」の品質を保つ（Implementation 層）
```

### 本プロジェクトで有効化すべき ECC コンポーネント

| コンポーネント          | 有効化   | 理由                                      |
| ----------------------- | -------- | ----------------------------------------- |
| rules/common            | Yes      | 言語非依存の基盤                          |
| rules/typescript        | Yes      | Next.js, NestJS で使用                    |
| rules/python            | Yes      | LangChain/LangGraph で使用                |
| rules/golang            | No       | 使用しない                                |
| tdd-guide agent         | Yes      | TDD の実施                                |
| code-reviewer agent     | Yes      | コード品質                                |
| security-reviewer agent | Yes      | セキュリティチェック                      |
| planner agent           | 状況次第 | cc-sdd と重複する可能性あり               |
| その他の agents         | No       | 必要になったら個別追加                    |
| 全 skills               | No       | Context 圧迫。/learn で必要なものだけ追加 |

### 入れなくてよいもの

- Go, Rust, Kotlin, Java, C++ 関連の rules / agents / skills
- 全43個以上の skills（Context を圧迫するだけ）
- MCP 設定の大半（必要になったら個別に追加）

---

## 10. 推奨 settings.json（テンプレート）

### User 設定: `~/.claude/settings.json`

全プロジェクト共通。Phase 0 で設定。

```json
{
  "$schema": "https://json.schemastore.org/claude-code-settings.json",
  "permissions": {
    "allow": [
      "Read",
      "Edit",
      "Write",
      "Bash(pnpm *)",
      "Bash(uv *)",
      "Bash(npx *)",
      "Bash(node *)",
      "Bash(python *)",
      "Bash(git status *)",
      "Bash(git diff *)",
      "Bash(git log *)",
      "Bash(git branch *)",
      "Bash(git checkout *)",
      "Bash(git switch *)",
      "Bash(git add *)",
      "Bash(git commit *)",
      "Bash(git stash *)",
      "Bash(git merge *)",
      "Bash(git rebase *)",
      "Bash(git fetch *)",
      "Bash(git remote *)",
      "Bash(git tag *)",
      "Bash(git cherry-pick *)",
      "Bash(git blame *)",
      "Bash(git show *)",
      "Bash(ls *)",
      "Bash(mkdir *)",
      "Bash(cp *)",
      "Bash(mv *)",
      "Bash(cat *)",
      "Bash(echo *)",
      "Bash(cd *)",
      "Bash(pwd)",
      "Bash(which *)",
      "Bash(where *)",
      "Bash(tsc *)",
      "Bash(eslint *)",
      "Bash(prettier *)",
      "Bash(jest *)",
      "Bash(vitest *)",
      "Bash(pytest *)"
    ],
    "ask": [
      "Bash(git push *)",
      "Bash(git push)",
      "Bash(cdk deploy *)",
      "Bash(cdk destroy *)"
    ],
    "deny": [
      "Bash(rm -rf /*)",
      "Bash(rm -rf ~*)",
      "Bash(rm -rf *)",
      "Bash(del /s /q *)",
      "Bash(rmdir /s /q *)",
      "Bash(aws iam *)",
      "Bash(aws sts *)",
      "Bash(aws organizations *)",
      "Bash(aws s3 rm *)",
      "Bash(aws s3 rb *)",
      "Bash(aws dynamodb delete-table *)",
      "Bash(aws lambda delete-function *)",
      "Bash(aws cloudformation delete-stack *)",
      "Bash(curl * | bash)",
      "Bash(curl * | sh)",
      "Bash(wget * | bash)",
      "Bash(ssh *)",
      "Bash(scp *)",
      "Bash(nc *)",
      "Bash(git push * --force)",
      "Bash(git push * -f)",
      "Bash(git reset --hard *)",
      "Bash(git clean -fd *)",
      "Bash(git clean -f *)",
      "Bash(* --no-verify)",
      "Bash(* --dangerously-skip-permissions)",
      "Read(//**/.env)",
      "Read(//**/.env.*)",
      "Read(~/.ssh/**)",
      "Read(~/.aws/**)",
      "Write(~/.ssh/**)",
      "Write(~/.aws/**)"
    ]
  },
  "language": "japanese",
  "includeCoAuthoredBy": false
}
```

### Project 設定: `.claude/settings.json`

チーム共有。Phase 5（設計確定後）で設定。

```json
{
  "$schema": "https://json.schemastore.org/claude-code-settings.json",
  "permissions": {
    "allow": [
      "Bash(cdk synth *)",
      "Bash(cdk diff *)",
      "Bash(cdk list *)",
      "Bash(docker build *)",
      "Bash(docker compose *)"
    ],
    "deny": [
      "Bash(cdk deploy * --require-approval never)"
    ]
  }
}
```

---

## 11. ECC ディレクトリ構造ガイド

`everything-claude-code` リポジトリの各ディレクトリの役割と、自分の `.claude/` に入れるべきかどうかをまとめる。

### `.claude/` にコピーして使うディレクトリ

| ディレクトリ       | 配置先                          | 説明                                                                                                                                              |
| ------------------ | ------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------- |
| **`.claude/`**     | `~/.claude/`                    | メインの設定ディレクトリ。commands, rules, skills, enterprise, homunculus, research, team を含む。丸ごとコピーで ECC フル構成になる               |
| **`commands/`**    | `~/.claude/commands/`           | `/build-fix`, `/checkpoint`, `/learn`, `/verify` など 49個のスラッシュコマンド。`/コマンド名` で呼び出せるワークフロー定義                        |
| **`skills/`**      | `~/.claude/skills/`             | 113個以上のドメイン知識モジュール。`nextjs-turbopack`, `python-patterns`, `api-design`, `tdd-workflow` など。必要な技術スタックのものだけ選択する |
| **`agents/`**      | プロジェクトルートの `.agents/` | 19個のエージェント定義。`architect.md`, `code-reviewer.md`, `security-reviewer.md` など。Claude が専門的なレビューや設計を行う際の役割定義        |
| **`rules/`**       | `~/.claude/rules/`              | 言語別コーディング規約。`common/`（共通）、`typescript/`、`python/` の3カテゴリ                                                                   |
| **`hooks/`**       | settings.json から参照          | ライフサイクルフック。ツール実行前後の自動チェック（`--no-verify` ブロック、自動フォーマット、セキュリティスキャンなど）                          |
| **`mcp-configs/`** | `~/.claude/mcp-servers.json`    | MCP サーバー設定。GitHub, Firecrawl, Supabase などの外部連携定義                                                                                  |
| **`contexts/`**    | `~/.claude/contexts/`           | コンテキストプリセット。dev / research / review の3種                                                                                             |

### `.claude/` の内部構造

`.claude/` ディレクトリ自体にもサブディレクトリがある。

| サブディレクトリ                 | 説明                                                                |
| -------------------------------- | ------------------------------------------------------------------- |
| `commands/`                      | ワークフローコマンドのテンプレート（`feature-development.md` など） |
| `rules/`                         | 言語別コーディング規約（`common/`, `typescript/`, `python/`）       |
| `skills/everything-claude-code/` | ECC リポジトリ自体の開発規約（commit パターン、コードスタイル）     |
| `enterprise/`                    | ガバナンス・セキュリティ審査フロー定義                              |
| `homunculus/instincts/`          | Claude の低レベルな推論パターン定義                                 |
| `research/`                      | リサーチプレイブック（ドキュメントファースト手法、ソース検証など）  |
| `team/`                          | チーム共有の設定（`everything-claude-code-team-config.json`）       |

### 参照・ドキュメント用（コピー不要）

| ディレクトリ     | 説明                                                                                                                          |
| ---------------- | ----------------------------------------------------------------------------------------------------------------------------- |
| **`docs/`**      | アーキテクチャ解説、トークン最適化ガイド、日本語翻訳（`ja-JP/`）など。読み物                                                  |
| **`examples/`**  | プロジェクト種別ごとの `CLAUDE.md` テンプレート（Next.js SaaS, Django, Go, Rust, Laravel）。自分の `CLAUDE.md` を書く際の参考 |
| **`schemas/`**   | JSON Schema 定義。設定ファイルのバリデーション・IDE 補完用                                                                    |
| **`manifests/`** | インストールプロファイル定義（minimal / standard / full）。`scripts/` のインストーラが参照する                                |
| **`scripts/`**   | ECC のインストーラ・CLI 本体（`ecc.js`）、ヘルスチェック、セッション管理など。ECC 自体の運用スクリプト                        |
| **`ecc2/`**      | Rust 製 TUI コントロールプレーン。開発初期段階（v0.1.0）                                                                      |
| **`tests/`**     | ECC 自体のテストスイート                                                                                                      |
| **`assets/`**    | ドキュメント用の画像                                                                                                          |
| **`.agents/`**   | `agents/` の他ハーネス向けコピー（Codex, Cursor 等）                                                                          |
| **`.github/`**   | GitHub Actions ワークフロー、PR テンプレート                                                                                  |
| **`plugins/`**   | プラグインの説明ドキュメント                                                                                                  |

### 本プロジェクトへの推奨インストール手順

技術スタック（Next.js + NestJS + Python/LangChain + AWS CDK）に基づいた最小構成。

#### Phase 1: 最小構成（Phase 0 でやること）

```bash
# 共通・言語固有ルール
cp -r everything-claude-code/rules/common ~/.claude/rules/
cp -r everything-claude-code/rules/typescript ~/.claude/rules/
cp -r everything-claude-code/rules/python ~/.claude/rules/

# 必要なスキルだけ選択
mkdir -p ~/.claude/skills
cp -r everything-claude-code/skills/nextjs-turbopack ~/.claude/skills/
cp -r everything-claude-code/skills/api-design ~/.claude/skills/
cp -r everything-claude-code/skills/python-patterns ~/.claude/skills/
cp -r everything-claude-code/skills/tdd-workflow ~/.claude/skills/
```

`examples/saas-nextjs-CLAUDE.md` を参考に自分の `CLAUDE.md` を作成する。

#### Phase 2: 設計確定後（Phase 5 でやること）

```bash
# エージェント（必要なものだけ）
mkdir -p .agents
cp everything-claude-code/agents/architect.md .agents/
cp everything-claude-code/agents/code-reviewer.md .agents/
cp everything-claude-code/agents/security-reviewer.md .agents/
cp everything-claude-code/agents/tdd-guide.md .agents/

# コマンド（必要なものだけ）
mkdir -p ~/.claude/commands
cp everything-claude-code/commands/build-fix.md ~/.claude/commands/
cp everything-claude-code/commands/verify.md ~/.claude/commands/
cp everything-claude-code/commands/learn.md ~/.claude/commands/
```

#### 本プロジェクトで入れなくてよいもの

- 使わない言語の `skills/`（Go, Rust, Kotlin, Java, Android など）
- `ecc2/`, `scripts/`, `tests/`, `schemas/`, `manifests/`（ECC 自体の運用用）
- `docs/`, `examples/`, `assets/`（読み物・参考資料）
- `mcp-configs/` の大半（必要になったら個別追加）
- `enterprise/`, `homunculus/`（個人開発では不要なことが多い）

---

## 参考リンク

| リソース                     | URL                                                                               |
| ---------------------------- | --------------------------------------------------------------------------------- |
| Everything Claude Code       | https://github.com/affaan-m/everything-claude-code                                |
| ECC 日本語ドキュメント       | https://github.com/affaan-m/everything-claude-code/blob/main/docs/ja-JP/README.md |
| cc-sdd                       | https://github.com/gotalab/cc-sdd                                                 |
| Claude Code 公式 Settings    | https://code.claude.com/docs/en/settings                                          |
| Claude Code 公式 Permissions | https://code.claude.com/docs/en/permissions                                       |
| Claude Code 公式 Hooks       | https://code.claude.com/docs/en/hooks-guide                                       |
