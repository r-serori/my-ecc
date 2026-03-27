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

```
/ecc-init          # プロジェクト初期化 + cc-sdd インストール
/ecc-bootstrap     # 安全方針 + 設計知識のインストール
```

### 4. cc-sdd で設計

```
/kiro:steering              # プロジェクト文脈の収集
/kiro:spec-init <feature>   # フィーチャーワークスペース作成
/kiro:spec-requirements     # 要件定義
/kiro:spec-design           # アーキテクチャ設計
/kiro:spec-tasks            # タスク分解
```

### 5. 実装コンポーネントのインストール

```
/ecc-configure     # 設計確定後、実装系コンポーネントをインストール
```

### 6. 開発 & 継続改善

```
/tdd               # TDD ワークフロー
/code-review       # コードレビュー
/ecc-evolve        # ECC 更新同期 + 継続改善コンポーネント
```

---

## コマンド一覧

| コマンド | 説明 | タイミング |
|---------|------|-----------|
| `/ecc-init` | プロジェクト初期セットアップ（cc-sdd install、settings.json、CLAUDE.md 生成） | 最初に1回 |
| `/ecc-bootstrap` | Tier 0 (安全方針) + Tier 1 (設計知識) インストール | cc-sdd 前 |
| `/ecc-configure` | Tier 2 (実装コンポーネント) インストール | cc-sdd 設計確定後 |
| `/ecc-evolve` | Tier 3 (継続改善) + ECC 更新差分の適用 | 開発中随時 |
| `/ecc-setup` | コマンドルーター / ヘルプ表示 | いつでも |

---

## Tier モデル

ECC コンポーネントを4つの Tier に分類し、段階的にインストールする。

| Tier | 名称 | 目的 | タイミング | 代表コンポーネント |
|------|------|------|-----------|-------------------|
| 0 | Safety | 破壊的操作の防止 | 最初に | settings.json permissions |
| 1 | Design Knowledge | 設計フェーズの品質向上 | cc-sdd 前 | architect agent, api-design skill, common rules |
| 2 | Implementation | 実装フェーズの品質・効率向上 | 設計確定後 | tdd-guide agent, 言語固有 rules, framework skills |
| 3 | Continuous | 継続的な改善・最適化 | 開発中随時 | continuous-learning skill, /learn command |

### なぜ段階的か

- **Context Window の保護**: 全コンポーネントを一度に入れると 200k → ~70k に縮小する
- **フェーズの整合性**: 実装ルール（TDD 必須等）が設計フェーズを阻害しない
- **選定根拠の追跡**: ecc-manifest.yaml で何をなぜ入れたか記録する

---

## ワークフロー全体像

```
/ecc-init
  │  cc-sdd install, settings.json, CLAUDE.md 生成
  ▼
/ecc-bootstrap
  │  Tier 0 (Safety) + Tier 1 (Design Knowledge)
  ▼
cc-sdd ─────────────────────────────────────────
  │  /kiro:steering
  │  /kiro:spec-init → spec-requirements → spec-design → spec-tasks
  │  ここで設計が確定
  ▼
/ecc-configure
  │  Tier 2 (Implementation) — 言語固有 rules, agents, commands
  ▼
TDD 実装 ───────────────────────────────────────
  │  /tdd, /code-review, /build-fix 等
  ▼
/ecc-evolve（随時）
     Tier 3 (Continuous) + ECC 更新差分の適用
```

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
│       ├── ecc-bootstrap.md       # Tier 0+1 インストーラー
│       ├── ecc-configure.md       # Tier 2 インストーラー
│       ├── ecc-evolve.md          # Tier 3 + 更新同期
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

### 基準ベース抽出

コンポーネント名をハードコードせず、description キーワードで知識ドメイン（Architecture, API Design, Security 等）に分類する。ECC がリネーム・統合・分割しても分類基準は壊れない。

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
