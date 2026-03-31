# my-ecc

> ECC (Everything Claude Code) x cc-sdd (Spec Driven Development) 統合ツール
> Claude Code プロジェクトの段階的セットアップを自動化する

---

## 概要

**cc-sdd** は「何を作るか」を決める構造化されたプロセス（要件定義 → 設計 → タスク分解）を提供するが、「良い設計とは何か」の知識は持っていない。

**ECC** は 125+ のスキル・28 エージェント・60 コマンド・12言語対応ルールという膨大な設計知識を持つが、プロジェクトフェーズに応じた選定ガイドがない。

**my-ecc** はこの2つを橋渡しする。ECC のコンポーネントを走査・分類し、cc-sdd の開発フェーズに合わせて段階的にインストールする。

```
cc-sdd = 試験の問題用紙（構造・形式・採点基準）
ECC    = 教科書（知識・パターン・ベストプラクティス）
my-ecc = 教科書から必要なページを選び、適切なタイミングで渡す仕組み
```

---

## 前提条件

| 必要なもの | 説明 |
|-----------|------|
| Claude Code CLI | v2.1.0+ |
| Git | クローン・バージョン管理用 |
| Node.js | npx が使用可能であること |
| ECC リポジトリ | クローン済み、または `$ECC_ROOT` 環境変数で指定 |

---

## クイックスタート

### 1. リポジトリをクローン

```bash
cd <workspace>
git clone https://github.com/r-serori/my-ecc.git
git clone https://github.com/affaan-m/everything-claude-code.git
```

### 2. プロジェクトにインストール

```bash
cd <workspace>
./my-ecc/install.sh <your-project-path>
```

または手動でコピー:

```bash
cp -r my-ecc/.claude/commands/ecc-*.md <project>/.claude/commands/
cp my-ecc/docs/ecc-shared-spec.md <project>/docs/
mkdir -p <project>/docs/ecc-templates
cp my-ecc/templates/* <project>/docs/ecc-templates/
```

### 3. Claude Code でセットアップ開始

```bash
cd <your-project>
claude
```

### 3.1. プロジェクト初期化 + cc-sdd インストール

```
/ecc-init
```

### 3.2. 上流工程支援コンポーネントのインストール

```
/ecc-bootstrap
```

Q0（プロジェクトタイプ）のみ質問される。言語・FW・ツールの質問はない。
Safety + 設計知識 + 品質方法論 + エンジニアリングパラダイム等がインストールされる。

### 4. cc-sdd で要件定義 + steering

```
/kiro:steering              # プロジェクト文脈・技術スタックの自動検出（Greenfield では空の場合あり）
/kiro:spec-init <feature>   # フィーチャーワークスペース作成
/kiro:spec-requirements     # 要件定義
```

**補足**: `/kiro:steering` は既存コードから技術スタックを自動検出します。Greenfield プロジェクトでは `tech.md` が空/プレースホルダーの場合があります。その場合、次のステップ `/ecc-configure` で Gap Fill 質問により技術スタックを入力・`tech.md` を自動生成します。

### 5. 実装コンポーネントのインストール

```
/ecc-configure     # tech.md が充実 → 自動抽出
                   # tech.md が空/未作成 → Gap Fill 質問 → tech.md 生成
                   # 言語固有 rules, FW skills, agents, MCP をインストール
```

### 6. 設計・実装

```
/kiro:spec-design <feature>     # アーキテクチャ設計（Discovery で技術調査・提案）
/kiro:spec-tasks <feature>      # タスク分解
/kiro:spec-impl <feature> <ids> # 実装
```

**注意**: 設計（spec-design）は `/ecc-configure` 後に行ってください。
技術スタックに適した skills と rules がインストールされた状態で設計することで、品質が最大化されます。

### 6.1. steering 同期（設計結果の反映）

```
/kiro:steering                  # sync モード — spec-design の技術決定を tech.md に反映
```

**重要**: `spec-design` の Discovery フェーズで新しい技術選定やアーキテクチャ決定が行われた場合、`/kiro:steering` を再実行して `tech.md` に反映してください。これにより、後続の `spec-tasks` や `spec-impl` が最新の技術スタックを参照できます。

技術スタックに大きな変更があった場合（例: フレームワーク変更、新しい言語の追加）:

```
/ecc-configure                  # 再実行 — 新しい技術に対応するコンポーネントを追加インストール
```

### 7. 開発 & 継続改善

```
/tdd               # TDD ワークフロー
/code-review       # コードレビュー
/ecc-evolve        # ECC 更新同期 + 継続改善コンポーネント
```

---

## ワークフロー全体像

```
/ecc-init
  │  cc-sdd install, settings.json, CLAUDE.md 生成
  ▼
/ecc-bootstrap（upstream scan — Q0 のみ）
  │  Safety + 設計知識 + 品質方法論 + エンジニアリングパラダイム
  │  ※ 言語/FW の除外なし。upstream_domains キーワードで分類
  ▼
/kiro:steering（自動検出。Greenfield では空の場合あり）
  │
  ▼
/kiro:spec-init → /kiro:spec-requirements
  │
  ▼
/ecc-configure（tech.md Gap 検出 → 質問 → tech.md 生成 → コンポーネントインストール）
  │  tech.md が充実 → 自動抽出
  │  tech.md が空/未作成 → Gap Fill → tech.md 生成
  │  言語固有 rules, framework skills, agents, MCP
  ▼
/kiro:spec-design（Discovery で技術調査・提案）
  │
  ▼
/kiro:steering（sync — design 結果を tech.md に反映）★
  │
  ▼
(/ecc-configure 再実行 — 技術変更があった場合のみ)
  │
  ▼
/kiro:spec-tasks → /kiro:spec-impl
  │
  ▼
TDD 実装 ───────────────────────────────────
  │  /tdd, /code-review, /build-fix 等
  ▼
/ecc-evolve（随時）
     継続改善 + ECC 更新差分の適用
```

### 各ステップの詳細

| ステップ | 何が起きるか | 入力 | 出力 |
|---------|-------------|------|------|
| `/ecc-init` | プロジェクト初期化、cc-sdd install、設定ファイル生成 | プロジェクト名、概要、パッケージマネージャー | settings.json, CLAUDE.md, .gitignore |
| `/ecc-bootstrap` | 上流工程支援コンポーネントのスキャン・インストール | Q0（プロジェクトタイプ） | Safety rules, 設計 skills, agents, commands, MCP |
| cc-sdd steering | プロジェクト文脈・技術スタックの自動検出 | 既存コード（Greenfield では空） | `.kiro/steering/tech.md`（空の場合あり） |
| cc-sdd spec | 要件定義（EARS format） | ユーザー対話 | `.kiro/specs/<feature>/requirements.md` |
| `/ecc-configure` | Gap 検出 → tech.md 生成（必要時）→ コンポーネントインストール | tech.md（自動）/ Gap Fill 質問（空の場合） | tech.md（生成時）, 言語 rules, FW skills, agents, MCP |
| cc-sdd design | アーキテクチャ設計（Discovery で技術調査・提案） | 要件 + インストール済みコンポーネント | `design.md`, `tasks.md` |
| steering sync ★ | spec-design の技術決定を tech.md に反映 | design.md の技術選定 | 更新された `tech.md` |
| `/ecc-configure`（再実行） | 技術変更時のみ。新規コンポーネントを追加インストール | 更新された tech.md | 追加の rules, skills, agents, MCP |
| `/ecc-evolve` | 継続改善コンポーネント + ECC 更新差分 | manifest | 更新された components |

### なぜ `/ecc-configure` の前に spec-design をしないのか

`/ecc-configure` は技術スタックに適した rules, skills, agents をインストールする。これらが存在しない状態で設計（spec-design）を行うと:

- 言語固有のコーディング規約が設計に反映されない
- フレームワーク固有のパターン（例: Next.js の App Router パターン）が考慮されない
- テスト戦略（例: Vitest vs Jest）が設計に組み込まれない

設計の質を最大化するために、実装支援コンポーネントは設計フェーズの**前に**インストールする。

### なぜ spec-design 後に steering sync が必要か

`spec-design` の Discovery フェーズでは、要件を満たすための技術調査・比較検討が行われる。この過程で:

- 新しいライブラリの採用が決まる（例: 状態管理に Zustand を選定）
- インフラ構成が具体化する（例: AWS Lambda → ECS に変更）
- 当初「未定」だった項目が確定する

これらの技術決定は `design.md` に記録されるが、`tech.md` には自動反映されない。`/kiro:steering` を再実行（sync モード）することで、design の技術決定が `tech.md` に反映され、後続の `spec-tasks` や `spec-impl` が正確な技術スタック情報を参照できるようになる。

技術スタックに大きな変更があった場合は `/ecc-configure` を再実行することで、新しい技術に対応する rules, skills, agents が追加インストールされる。

---

## コマンド一覧

| コマンド | 説明 | タイミング |
|---------|------|-----------|
| `/ecc-init` | プロジェクト初期セットアップ（cc-sdd install、settings.json、CLAUDE.md 生成） | 最初に1回 |
| `/ecc-bootstrap` | Upstream（安全方針 + 設計知識）インストール — Q0 のみ、cc-sdd 前 | cc-sdd 前 |
| `/ecc-configure` | Tech Stack Gap 検出 + tech.md 生成（必要時）+ Downstream インストール | cc-sdd steering 後 |
| `/ecc-evolve` | 継続改善コンポーネント + ECC 更新差分の適用 | 開発中随時 |
| `/ecc-setup` | コマンドルーター / ヘルプ表示 | いつでも |

---

## Phase モデル

ECC コンポーネントを 3 つの Phase に分類し、ワークフロー段階に合わせてインストールする。

| Phase | 名称 | 目的 | タイミング | スキャンモード |
|-------|------|------|-----------|--------------|
| Upstream | 上流工程支援 | 要件定義・設計方針の品質向上 | cc-sdd 前 | upstream_domains キーワード |
| Downstream | 実装支援 | 実装フェーズの品質・効率向上 | cc-sdd steering 後 | 言語/FW/ツール キーワード |
| Continuous | 継続改善 | パターン抽出・最適化 | 開発中随時 | 継続改善キーワード |

### 代表コンポーネント

| Phase | Skills | Agents | Rules |
|-------|--------|--------|-------|
| Upstream | safety-guard, product-lens, architecture-decision-records, tdd-workflow, agentic-engineering, agent-eval, coding-standards, verification-loop | architect, planner, security-reviewer | common/ |
| Downstream | frontend-patterns, python-patterns, nextjs-turbopack, docker-patterns, e2e-testing | tdd-guide, code-reviewer, typescript-reviewer | typescript/, python/ |
| Continuous | continuous-learning, rules-distill, context-budget | — | — |

### なぜ段階的か

- **Context Window の保護**: 全コンポーネントを一度に入れると 200k → ~70k に縮小する
- **フェーズの整合性**: 実装ルール（言語固有 linting 等）が要件定義フェーズを阻害しない
- **選定精度の向上**: 技術スタック確定後にスコアリングすることで、不要なコンポーネントの除外精度が上がる
- **選定根拠の追跡**: ecc-manifest.yaml で何をなぜ入れたか記録する

---

## upstream_domains 詳細

bootstrap mode でコンポーネントを分類する 7 つのドメイン:

### safety（自動インストール）

**目的**: 全工程で破壊的操作を防止する基盤。

- **Keywords**: destructive operation prevention, permission guard, safety policy
- **代表**: `safety-guard` skill, settings.json permission template
- **理由**: プロジェクト開始時点から保護が必要。後からインストールしても、それまでの操作は保護されない。

### design_methodology

**目的**: 要件定義・アーキテクチャ設計の判断基準を提供する。

- **Keywords**: architecture, system design, ADR, decision record, product thinking, requirements, MVP, blueprint, modularity, scalability, layering, API design, REST, resource naming, schema design, database patterns, indexing, frontend design, component composition, state management, design system, backend design, service layer, repository pattern, dependency injection, caching strategies, N+1 prevention, performance optimization
- **代表**: `architecture-decision-records`, `product-lens`, `api-design`, `frontend-patterns`, `backend-patterns`, `postgres-patterns`
- **理由**: 設計パターンの知識がないと、cc-sdd の spec-design で浅い設計になる。「どのパターンを使うべきか」の判断基準が Claude に提供される。

### quality_methodology

**目的**: 設計段階で品質方針（テスト戦略、コードレビュー基準）を決定する。

- **Keywords**: TDD, test-driven, test strategy, verification, code review, quality gate, coding standards
- **代表**: `tdd-workflow`, `coding-standards`, `verification-loop`
- **理由**: TDD の方法論を理解していると、テスト可能なインターフェース設計が自然に生まれる。品質方針は設計に組み込むべきであり、実装後に追加するものではない。

### engineering_paradigm

**目的**: エージェント活用等のパラダイムはアーキテクチャ判断に直接影響する。

- **Keywords**: agentic engineering, eval-first, agent architecture, multi-agent, cost-aware, decomposition, harness, agent eval
- **代表**: `agentic-engineering`, `agent-eval`, `agent-harness-construction`
- **理由**: LangGraph 等のエージェントフレームワークを使用する場合、エージェント設計パターン（eval-first, decomposition）を要件定義段階で理解しておく必要がある。これらはアーキテクチャの根幹に関わる。

### security_design

**目的**: セキュリティ設計方針は要件定義段階で決定が必要。

- **Keywords**: security design, OWASP, authentication architecture, secrets management, authorization
- **代表**: `security-review` skill, `security-reviewer` agent
- **理由**: 認証・認可のアーキテクチャは後付けが極めて困難。要件定義段階でセキュリティ要件を明確にし、設計に反映する。

### workflow_foundation

**目的**: 開発ワークフローの基盤は最初に確立する。

- **Keywords**: git workflow, research-first, plan-first, coding style, immutability, continuous learning
- **代表**: `git-workflow` skill, common rules (coding-style, development-workflow)
- **理由**: コミット規約、ブランチ戦略、コーディングスタイル（イミュータビリティ）は全工程に影響する。

### common_rules（自動インストール）

**目的**: 共通ルールは全工程に適用される。

- **対象**: `rules/common/` ディレクトリ全体
- **代表**: coding-style.md, testing.md, security.md, git-workflow.md, development-workflow.md 等
- **理由**: 言語/FW に依存しない基盤ルール。

---

## Tech Stack 自動抽出

`/ecc-configure` は以下の優先順位で技術スタックを自動検出する。

### Priority 1: `.kiro/steering/tech.md`（推奨）

cc-sdd の `/kiro:steering` コマンドが生成する技術スタック定義ファイル。以下のセクションをパースする:

- **Language** / **言語** → `tech_stack.languages`
- **Framework** / **フレームワーク** → `tech_stack.frameworks`
- **Key Libraries** → `tech_stack.frameworks`（追加）
- **Required Tools** / **ツール** → `tech_stack.tools`

**Sparse Detection**: tech.md が存在してもプレースホルダー（`[e.g.,` 等）のみの場合、「sparse」と判定し Gap Fill にフォールスルーする。Greenfield プロジェクトで `/kiro:steering` が空のテンプレートを生成した場合に対応する。

**なぜ steering が推奨か**: cc-sdd のプロセスを経て確定した技術スタックであるため、最も信頼性が高い。

### Priority 2: `CLAUDE.md` の Tech Stack 行

`**Tech Stack:**` 行をパースし、カンマ/パイプ区切りで技術名を抽出。ECC の Classification Keywords に照合して languages/frameworks/tools に分類する。

**ユースケース**: cc-sdd を使用しないプロジェクト、または steering を省略した場合。

### Priority 3: Gap Fill（構造化質問 → tech.md 生成）

Priority 1 が存在しない、またはプレースホルダーのみの場合、かつ Priority 2 も利用できない場合、構造化された単一の質問でユーザーに技術スタックを入力してもらう。回答から `tech.md` を cc-sdd テンプレート形式で自動生成し、`.kiro/steering/tech.md` に書き出す。

**ユースケース**: Greenfield プロジェクトで `/kiro:steering` が空の tech.md を生成した場合、または cc-sdd を省略した場合。

---

## ECC パス解決

ECC リポジトリのパスは以下の優先順で解決される:

| 優先度 | 方法 | 説明 |
|--------|------|------|
| 1 | `$ECC_ROOT` 環境変数 | `export ECC_ROOT=/path/to/everything-claude-code` |
| 2 | `ecc-manifest.yaml` の `ecc.source` | bootstrap 後に自動記録 |
| 3 | `../everything-claude-code/` | プロジェクトと同じ階層にクローンした場合 |

---

## CLAUDE.md 戦略（200行以内）

公式推奨の200行以内を維持するため、3層のポインター戦略を採用:

| 層 | 内容 | 方法 |
|---|------|------|
| **Direct** | プロジェクト概要、Critical Rules 要約 | CLAUDE.md に直接記述 |
| **Pointer** | 設計ドキュメント、rules、コンポーネント一覧 | `.kiro/specs/`, `.claude/rules/`, `ecc-manifest.yaml` を参照 |
| **Delta** | 他に記載のない例外情報のみ | 環境変数、プロジェクト固有の制約 |

`/ecc-init` が CLAUDE.md のスケルトンを生成する。設計知識や rules の詳細は各ファイルに委譲し、CLAUDE.md には書かない。

---

## ディレクトリ構造

```
my-ecc/
├── .claude/
│   ├── settings.json              # my-ecc 開発用 permissions
│   └── commands/
│       ├── ecc-init.md            # プロジェクト初期化コマンド
│       ├── ecc-bootstrap.md       # Upstream インストーラー
│       ├── ecc-configure.md       # Tech Stack 抽出 + Downstream インストーラー
│       ├── ecc-evolve.md          # 継続改善 + 更新同期
│       └── ecc-setup.md           # ルーター / ヘルプ
├── docs/
│   ├── ecc-shared-spec.md         # 共有ランタイム仕様（遅延読み込み）
│   └── ecc-extraction-analysis.md # 設計根拠ドキュメント
├── templates/
│   ├── settings.json              # プロジェクト向け permission テンプレート
│   ├── CLAUDE.md.template         # CLAUDE.md スケルトン（ポインター戦略）
│   └── gitignore.append           # .gitignore 追記用エントリ
├── install.sh                     # インストーラースクリプト
├── README.md                      # 本ドキュメント
└── LICENSE                        # MIT License
```

---

## 設計思想

### Phase-Aware Classification

コンポーネントをワークフロー段階（upstream / downstream / continuous）に基づいて分類する。

bootstrap は「上流工程に必要か？」で判定し、configure は「確定した tech stack に対して有用か？」で判定する。これにより、`tdd-workflow` や `agentic-engineering` のような方法論コンポーネントが、技術スタック未確定の段階でも正しく推奨される。

### 基準ベース抽出

コンポーネント名をハードコードせず、description キーワードで知識ドメインに分類する。ECC がリネーム・統合・分割しても分類基準は壊れない。

### Tech Stack 自動抽出

cc-sdd steering の成果物（`.kiro/steering/tech.md`）から技術スタックを自動抽出する。手動入力の手間を省き、cc-sdd との整合性を保つ。

### 遅延読み込み

コマンドファイルは軽量に保ち（~1,000 tokens）、共有仕様（ecc-shared-spec.md）は Read ツール経由で遅延読み込みする。Context Window への影響を最小化。

### cc-sdd との補完関係

```
cc-sdd  = 「何を作るか」を決めるプロセス（Spec 層）
ECC     = 「どう作るか」の品質を保つ知識（Implementation 層）
my-ecc  = 両者を適切なタイミングで接続する橋渡し
```

---

## 関連プロジェクト

- [everything-claude-code](https://github.com/affaan-m/everything-claude-code) — Claude Code 向けの包括的なスキル・エージェント・ルール集
- [cc-sdd](https://www.npmjs.com/package/cc-sdd) — 仕様駆動開発 (Spec Driven Development) ツール

---

## ライセンス

MIT License. 詳細は [LICENSE](LICENSE) を参照。
