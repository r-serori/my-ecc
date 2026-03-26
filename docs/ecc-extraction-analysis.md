# ECC 抽出分析ドキュメント

> cc-sdd と ECC を組み合わせて開発する際に、**なぜ ECC から特定のコンポーネントを抽出する必要があるのか**、その判断根拠を記録する。

---

## 1. 概要

### 問題

cc-sdd（Spec Driven Development）は要件定義から設計・実装までのワークフローを提供するが、**設計知識そのもの**は持っていない。

ECC（Everything Claude Code）は 197 個のコンポーネント（skills, agents, rules, commands）を持つが、**プロジェクトフェーズに応じた選定ガイドがない**。

### 解決策

`/ecc-setup` コマンドを作成し、以下を自動化する:

1. ECC の全コンポーネントを走査
2. description ベースで Tier（設計知識 / 実装 / 継続改善）に分類
3. ユーザーのテックスタックでフィルタ
4. 承認されたものをインストール
5. マニフェストとレポートで追跡

---

## 2. cc-sdd に足りないもの

### cc-sdd が提供するもの

cc-sdd は8フェーズの構造化されたワークフローを提供する:

| Phase | コマンド | 生成物 |
| --- | --- | --- |
| 1. Steering | `/kiro:steering` | プロジェクト文脈・規約 |
| 2. Spec Init | `/kiro:spec-init` | フィーチャーワークスペース |
| 3. Requirements | `/kiro:spec-requirements` | EARS 形式の要件定義 |
| 4. Design | `/kiro:spec-design` | アーキテクチャ設計（Mermaid 図含む） |
| 5. Tasks | `/kiro:spec-tasks` | 実装タスク分解 |
| 6. Implementation | `/kiro:spec-impl` | コード |
| 7. Validate | `/kiro:validate-*` | ギャップ分析・設計検証 |
| 8. Status | `/kiro:spec-status` | 進捗確認 |

### cc-sdd が提供しないもの

cc-sdd は **「設計ドキュメントを生成するプロセス」** を提供するが、**「良い設計とは何か」の知識** は持っていない。

| 知識領域 | cc-sdd が提供するもの | cc-sdd に無いもの |
| --- | --- | --- |
| 要件定義 | EARS 形式テンプレート | - |
| アーキテクチャ | design.md 生成プロセス | パターン知識（Repository, Service Layer, CQRS 等） |
| API 設計 | - | REST 規約、ステータスコード、ページネーション、バージョニング |
| データ設計 | - | スキーマ設計、インデックス戦略、正規化 |
| セキュリティ設計 | - | OWASP、認証アーキテクチャ、シークレット管理 |
| パフォーマンス設計 | - | キャッシュ戦略、N+1 防止、スケーリング |
| フロントエンド設計 | - | コンポーネント構成、状態管理パターン |
| バックエンド設計 | - | サービス層、ミドルウェア、リポジトリパターン |
| 意思決定記録 | - | ADR 形式、トレードオフ分析 |
| コーディング規約 | - | 不変性、ファイル構成、エラーハンドリング |
| テスト戦略 | - | TDD、カバレッジ基準、E2E |
| Git ワークフロー | - | コミット規約、PR プロセス |

### 例え

```
cc-sdd = 試験の問題用紙（構造・形式・採点基準）
ECC    = 教科書（知識・パターン・ベストプラクティス）
```

問題用紙だけ渡して教科書なしで試験を受けさせている状態。cc-sdd の設計フェーズで Claude が出す設計の質は、ECC の設計系コンポーネントを入れた場合と入れない場合で明確に変わる。

---

## 3. ECC が埋めるギャップ

### 知識ドメインと対応コンポーネント

| 知識ドメイン | ECC コンポーネント | Type | 提供する知識 |
| --- | --- | --- | --- |
| **Architecture** | `architect` | agent | システム設計、モジュール構造、スケーラビリティ、パターン（Repository, Service Layer, CQRS）、ADR、レッドフラグ検出 |
| | `planner` | agent | 実装計画、リスク評価、フェーズ分解 |
| | `backend-patterns` | skill | Repository Pattern, Service Layer, Middleware, Caching Strategies |
| | `codebase-onboarding` | skill | アーキテクチャマッピング、エントリーポイント、規約発見 |
| **API Design** | `api-design` | skill | REST 規約、リソース命名、ステータスコード、ページネーション、フィルタリング、バージョニング、レート制限 |
| **Data Design** | `postgres-patterns` | skill | スキーマ設計、インデックス最適化、クエリ最適化、RLS |
| | `database-migrations` | skill | 安全なマイグレーション、ゼロダウンタイムスキーマ変更 |
| **Security Design** | `security-review` | skill | 認証・認可チェックリスト、OWASP、シークレット管理 |
| | `common/security.md` | rule | 必須セキュリティチェック（ハードコードシークレット、SQL インジェクション、XSS、CSRF） |
| **Performance** | `common/performance.md` | rule | モデル選択戦略、コンテキストウィンドウ管理 |
| **Frontend Design** | `frontend-patterns` | skill | コンポーネント構成、状態管理、データフェッチ、パフォーマンス |
| | `design-system` | skill | デザイントークン生成、ビジュアル監査 |
| **Backend Design** | `backend-patterns` | skill | Service Layer, Repository, Middleware |
| **Decision Records** | `architecture-decision-records` | skill | ADR 形式、代替案記録、結果追跡 |
| **Requirements** | `product-lens` | skill | 要件検証、MVP 定義、アンチゴール |
| **Coding Standards** | `coding-standards` | skill | 可読性、KISS、不変性、ファイル構成 |
| | `common/coding-style.md` | rule | 不変性、ファイル構成（200-400 行）、エラーハンドリング |
| **Workflow** | `common/development-workflow.md` | rule | Research-first, Plan-first, TDD, Code Review |
| | `common/git-workflow.md` | rule | Conventional Commits、PR プロセス |
| **Testing** | `common/testing.md` | rule | 80% 最低カバレッジ、TDD 必須ワークフロー |

---

## 4. Tier モデルの根拠

### なぜ Tier に分けるのか

全コンポーネントを一度にインストールすると:

1. **Context Window を圧迫する** — 200k のウィンドウがツール有効化で ~70k に縮小する
2. **不要なルールが設計を歪める** — 実装フェーズのルール（TDD 必須等）が設計フェーズを阻害する
3. **選定根拠が不明になる** — なぜそのコンポーネントを入れたのか追跡できない

### Tier 定義

```
Tier 0: Safety
  ├─ タイミング: 最初に（全フェーズ共通）
  ├─ 目的: 破壊的操作の防止
  └─ 例: safety-guard skill, settings.json permissions

Tier 1: Design Knowledge
  ├─ タイミング: cc-sdd 前
  ├─ 目的: 設計フェーズの品質向上
  ├─ 特徴: 言語/FW 非依存（設計知識は普遍的）
  └─ 例: architect agent, api-design skill, common/ rules

Tier 2: Implementation
  ├─ タイミング: cc-sdd 設計確定後
  ├─ 目的: 実装フェーズの品質・効率向上
  ├─ 特徴: テックスタック依存（言語固有ルール等）
  └─ 例: tdd-guide agent, rules/typescript/*, nextjs-turbopack skill

Tier 3: Continuous
  ├─ タイミング: 開発中に随時
  ├─ 目的: 継続的な改善・最適化
  └─ 例: continuous-learning skill, /learn command
```

### 鶏と卵問題の解消

| 問題 | 解決 |
| --- | --- |
| 設計系 skills/agents は cc-sdd 前に必要 | → Tier 1 で bootstrap 時にインストール |
| 言語固有 rules は設計確定後に必要 | → Tier 2 で configure 時にインストール |
| 継続改善は開発中に必要 | → Tier 3 で evolve 時にインストール |
| cc-sdd のプロセスと競合しないか | → cc-sdd = プロセス、ECC = 知識。補完関係 |

---

## 5. 全コンポーネント分類表

### Tier 1: Design Knowledge（言語/FW 非依存）

| Name | Type | Domain | 説明 |
| --- | --- | --- | --- |
| api-design | skill | API Design | REST API 設計パターン、リソース命名、ステータスコード、ページネーション |
| architecture-decision-records | skill | Architecture | ADR 形式、代替案分析、結果追跡 |
| backend-patterns | skill | Backend Design | Repository Pattern, Service Layer, Middleware, Caching |
| frontend-patterns | skill | Frontend Design | React コンポーネント構成、状態管理、データフェッチ |
| postgres-patterns | skill | Data Design | スキーマ設計、インデックス最適化、RLS |
| database-migrations | skill | Data Design | 安全なマイグレーション、ゼロダウンタイム |
| security-review | skill | Security | 認証・認可チェックリスト、OWASP |
| design-system | skill | Frontend Design | デザイントークン生成、ビジュアル監査 |
| product-lens | skill | Requirements | 要件検証、MVP 定義、アンチゴール |
| coding-standards | skill | General | 可読性、KISS、不変性 |
| codebase-onboarding | skill | Architecture | アーキテクチャマッピング、エントリーポイント |
| safety-guard | skill | Safety | 破壊的操作の防止 |
| architect | agent | Architecture | システム設計、スケーラビリティ、トレードオフ（Opus） |
| planner | agent | Architecture | 実装計画、リスク評価、フェーズ分解（Opus） |
| common/agents.md | rule | Agents | エージェント利用ガイド |
| common/coding-style.md | rule | Coding Style | 不変性、ファイル構成、エラーハンドリング |
| common/development-workflow.md | rule | Workflow | Research-first, Plan-first パイプライン |
| common/git-workflow.md | rule | Git | Conventional Commits、PR ワークフロー |
| common/hooks.md | rule | Hooks | フックシステムパターン |
| common/patterns.md | rule | Patterns | Repository Pattern, API Response Format |
| common/performance.md | rule | Performance | モデル選択、コンテキスト管理 |
| common/security.md | rule | Security | 必須セキュリティチェック |
| common/testing.md | rule | Testing | 80% カバレッジ、TDD 必須 |
| plan | command | Architecture | 実装計画コマンド |

### Tier 2: Implementation（テックスタック依存）

#### 言語非依存（常にインストール候補）

| Name | Type | Domain | 説明 |
| --- | --- | --- | --- |
| tdd-workflow | skill | Testing | TDD 強制、80%+ カバレッジ |
| e2e-testing | skill | Testing | Playwright E2E テストパターン |
| verification-loop | skill | Quality | 包括的検証システム |
| search-first | skill | Workflow | Research-before-coding |
| deployment-patterns | skill | DevOps | CI/CD、Docker、Blue-Green、Canary |
| docker-patterns | skill | DevOps | Docker Compose、マルチサービス |
| blueprint | skill | Planning | マルチセッションプロジェクト計画 |
| prompt-optimizer | skill | AI | プロンプト最適化パターン |
| code-reviewer | agent | Review | コード品質・セキュリティレビュー（Sonnet） |
| tdd-guide | agent | Testing | TDD 強制エージェント（Sonnet） |
| build-error-resolver | agent | Build | ビルドエラー診断（Sonnet） |
| e2e-runner | agent | Testing | Playwright E2E テスト（Sonnet） |
| security-reviewer | agent | Security | セキュリティ脆弱性分析（Sonnet） |
| refactor-cleaner | agent | Quality | デッドコードクリーンアップ（Sonnet） |
| doc-updater | agent | Docs | ドキュメント更新（Haiku） |
| tdd | command | Testing | TDD ワークフローコマンド |
| code-review | command | Review | コードレビューコマンド |
| build-fix | command | Build | ビルドエラー修正コマンド |
| verify | command | Quality | 検証コマンド |
| e2e | command | Testing | E2E テストコマンド |
| test-coverage | command | Testing | カバレッジ分析コマンド |
| refactor-clean | command | Quality | リファクタリングコマンド |
| quality-gate | command | Quality | 品質ゲートチェック |
| update-docs | command | Docs | ドキュメント更新コマンド |

#### TypeScript 選択時に追加

| Name | Type | Domain | 説明 |
| --- | --- | --- | --- |
| nextjs-turbopack | skill | Framework | Next.js 16+、Turbopack パターン |
| typescript-reviewer | agent | Review | TypeScript コードレビュー（Sonnet） |
| typescript/coding-style.md | rule | Coding Style | TS/JS 固有のコーディングスタイル |
| typescript/patterns.md | rule | Patterns | TS/JS パターン（API レスポンス、Hooks） |
| typescript/testing.md | rule | Testing | TS/JS テストパターン |
| typescript/security.md | rule | Security | TS/JS セキュリティパターン |
| typescript/hooks.md | rule | Hooks | TS/JS フックパターン |

#### Python 選択時に追加

| Name | Type | Domain | 説明 |
| --- | --- | --- | --- |
| python-patterns | skill | Language | Pythonic イディオム、PEP 8、型ヒント |
| python-testing | skill | Testing | pytest、TDD、フィクスチャ、モック |
| python-reviewer | agent | Review | Python コードレビュー（Sonnet） |
| python-review | command | Review | Python レビューコマンド |
| python/coding-style.md | rule | Coding Style | Python 固有のコーディングスタイル |
| python/patterns.md | rule | Patterns | Python パターン（Protocol、dataclasses） |
| python/testing.md | rule | Testing | Python テストパターン |
| python/security.md | rule | Security | Python セキュリティパターン |
| python/hooks.md | rule | Hooks | Python フックパターン |

#### AI/Agent プロジェクト選択時に追加

| Name | Type | Domain | 説明 |
| --- | --- | --- | --- |
| agentic-engineering | skill | AI | Eval-first 実行、モデルルーティング |
| ai-first-engineering | skill | AI | AI エージェントチーム運用モデル |
| cost-aware-llm-pipeline | skill | AI | LLM コスト最適化、モデルルーティング |
| claude-api | skill | AI | Claude API パターン、ストリーミング、ツール使用 |
| deep-research | skill | AI | マルチソースリサーチ、引用付きレポート |
| autonomous-loops | skill | AI | 自律エージェントループアーキテクチャ |
| mcp-server-patterns | skill | AI | MCP サーバー構築パターン |
| prompt-optimize | command | AI | プロンプト最適化コマンド |

### Tier 3: Continuous（テックスタック非依存）

| Name | Type | Domain | 説明 |
| --- | --- | --- | --- |
| continuous-learning | skill | Learning | セッションパターン抽出 |
| continuous-learning-v2 | skill | Learning | Instinct ベース学習、信頼度スコアリング |
| rules-distill | skill | Learning | 横断的原則のルール蒸留 |
| context-budget | skill | Optimization | コンテキストウィンドウ消費監査 |
| skill-stocktake | skill | Audit | スキル品質監査 |
| skill-comply | skill | Audit | コンプライアンス検証 |
| strategic-compact | skill | Optimization | コンテキスト圧縮 |
| learn | command | Learning | パターン抽出コマンド |
| evolve | command | Learning | Instinct 進化コマンド |
| rules-distill | command | Learning | ルール蒸留コマンド |
| context-budget | command | Optimization | コンテキスト予算コマンド |

### Excluded（除外）

#### 他言語/フレームワーク固有（テックスタック不一致で除外）

| Name | Type | 対象言語/FW |
| --- | --- | --- |
| django-patterns | skill | Python/Django |
| django-tdd | skill | Python/Django |
| django-verification | skill | Python/Django |
| django-security | skill | Python/Django |
| laravel-patterns | skill | PHP/Laravel |
| laravel-tdd | skill | PHP/Laravel |
| laravel-verification | skill | PHP/Laravel |
| laravel-security | skill | PHP/Laravel |
| springboot-patterns | skill | Java/Spring Boot |
| springboot-tdd | skill | Java/Spring Boot |
| springboot-verification | skill | Java/Spring Boot |
| springboot-security | skill | Java/Spring Boot |
| golang-patterns | skill | Go |
| golang-testing | skill | Go |
| kotlin-patterns | skill | Kotlin |
| kotlin-coroutines-flows | skill | Kotlin |
| kotlin-exposed-patterns | skill | Kotlin |
| kotlin-ktor-patterns | skill | Kotlin |
| kotlin-testing | skill | Kotlin |
| compose-multiplatform-patterns | skill | Kotlin |
| swift-concurrency-6-2 | skill | Swift |
| swift-actor-persistence | skill | Swift |
| swift-protocol-di-testing | skill | Swift |
| swiftui-patterns | skill | Swift |
| foundation-models-on-device | skill | Swift/Apple |
| liquid-glass-design | skill | Swift/Apple |
| android-clean-architecture | skill | Kotlin/Android |
| rust-patterns | skill | Rust |
| rust-testing | skill | Rust |
| cpp-coding-standards | skill | C++ |
| cpp-testing | skill | C++ |
| perl-patterns | skill | Perl |
| perl-testing | skill | Perl |
| perl-security | skill | Perl |
| java-coding-standards | skill | Java |
| jpa-patterns | skill | Java |
| clickhouse-io | skill | ClickHouse |
| bun-runtime | skill | Bun |
| flutter-dart-code-review | skill | Flutter/Dart |
| rust-reviewer | agent | Rust |
| rust-build-resolver | agent | Rust |
| pytorch-build-resolver | agent | PyTorch |
| database-reviewer | agent | PostgreSQL |
| rust-review | command | Rust |
| rust-test | command | Rust |
| gradle-build | command | Java/Gradle |

#### ドメイン固有（プロジェクトドメイン不一致で除外）

| Name | Type | ドメイン |
| --- | --- | --- |
| carrier-relationship-management | skill | Supply Chain |
| customs-trade-compliance | skill | Supply Chain |
| energy-procurement | skill | Supply Chain |
| inventory-demand-planning | skill | Supply Chain |
| logistics-exception-management | skill | Supply Chain |
| production-scheduling | skill | Supply Chain |
| quality-nonconformance | skill | Supply Chain |
| returns-reverse-logistics | skill | Supply Chain |
| article-writing | skill | Content |
| content-engine | skill | Content |
| crosspost | skill | Social |
| x-api | skill | Social |
| fal-ai-media | skill | Media |
| video-editing | skill | Media |
| videodb | skill | Media |
| investor-materials | skill | Business |
| investor-outreach | skill | Business |
| market-research | skill | Business |
| frontend-slides | skill | Presentation |
| nutrient-document-processing | skill | Document |
| visa-doc-translate | skill | Document |

#### 特殊ツール/メタ（汎用利用が想定されていない）

| Name | Type | 理由 |
| --- | --- | --- |
| configure-ecc | skill | 本コマンドで置換 |
| everything-claude-code | skill | ECC 自体の開発用 |
| agent-eval | skill | エージェント比較（特殊用途） |
| agent-harness-construction | skill | ハーネス構築（特殊用途） |
| benchmark | skill | パフォーマンスベースライン（特殊用途） |
| browser-qa | skill | ブラウザ QA（特殊用途） |
| canary-watch | skill | カナリア監視（特殊用途） |
| click-path-audit | skill | ユーザーフロー監査（特殊用途） |
| claude-devfleet | skill | DevFleet オーケストレーション |
| data-scraper-agent | skill | データスクレイピング |
| dmux-workflows | skill | dmux マルチエージェント |
| documentation-lookup | skill | Context7 連携（MCP 依存） |
| enterprise-agent-ops | skill | エンタープライズ運用 |
| exa-search | skill | Exa MCP 連携（MCP 依存） |
| eval-harness | skill | 評価ハーネス |
| nanoclaw-repl | skill | NanoClaw REPL |
| plankton-code-quality | skill | Plankton hooks 連携 |
| ralphinho-rfc-pipeline | skill | RFC パイプライン |
| regex-vs-llm-structured-text | skill | パース手法判定 |
| santa-method | skill | 対立的検証 |
| team-builder | skill | チーム構成 |
| content-hash-cache-pattern | skill | キャッシュパターン |
| continuous-agent-loop | skill | 自律ループ（autonomous-loops と重複） |
| iterative-retrieval | skill | コンテキスト段階精緻化 |
| project-guidelines-example | skill | テンプレート |
| ai-regression-testing | skill | AI 回帰テスト |
| chief-of-staff | agent | トリアージ（特殊用途） |
| harness-optimizer | agent | ハーネス最適化 |
| loop-operator | agent | ループ運用 |
| docs-lookup | agent | Context7 連携 |

---

## 6. 基準ベース抽出の設計

### なぜリストではなく基準なのか

```
❌ 脆弱な設計（コンポーネント名をハードコード）
   "api-design, backend-patterns, architect をインストールせよ"
   → ECC がリネーム/統合/分割したら壊れる

✅ 堅牢な設計（探索基準を定義）
   "設計フェーズに必要な知識を持つ全コンポーネントを探索せよ"
   → ECC 構造が変わっても、メタデータを読んで判定できる
```

### 基準の安定性

分類基準は **知識ドメイン** に基づいている:

- Architecture, API Design, Data Design, Security, Performance, Frontend, Backend, ADR, Testing, DevOps

これらのドメインは **ソフトウェア工学の普遍的な分類** であり、ECC のバージョンに依存しない。

### ECC コンポーネントのメタデータ

全コンポーネントには以下のメタデータがある:

**Skills** (`SKILL.md`):

```yaml
---
name: api-design
description: REST API design patterns including resource naming, status codes...
origin: ECC
---
```

+ `## When to Activate` セクション

**Agents** (`.md`):

```yaml
---
name: architect
description: Software architecture specialist for system design...
model: opus
---
```

**Rules** (`.md`):

```yaml
---
paths:
  - "**/*.ts"
  - "**/*.tsx"
---
```

**Commands** (`.md`):

```yaml
---
description: Restate requirements, assess risks, and create step-by-step implementation plan.
---
```

Claude はこれらの description を読んで、知識ドメインとの照合を行う。

---

## 7. ECC 更新耐性

### 新コンポーネント追加時

ECC に `graphql-design` skill が追加された場合:

1. `/ecc-setup evolve` がスキャン時に新しい SKILL.md を発見
2. description: "GraphQL schema design patterns, resolvers, and type system" を読む
3. 「design」「schema」「patterns」から Tier 1（Design Knowledge）に分類
4. ユーザーに通知: 「新しい設計知識スキルが利用可能です: graphql-design」

### コンポーネントリネーム時

`backend-patterns` が `server-architecture` にリネームされた場合:

1. マニフェストの `backend-patterns` が見つからない → 「削除された可能性」フラグ
2. 新しい `server-architecture` の description を読む → 同じドメイン（Backend Design）と判定
3. ユーザーに通知: 「backend-patterns が削除され、server-architecture が追加されました。更新しますか？」

### コンポーネント統合時

`api-design` と `backend-patterns` が `server-engineering` に統合された場合:

1. 両方がマニフェストから見つからない → 「削除された可能性」フラグ
2. 新しい `server-engineering` がカバーするドメインを判定
3. ユーザーに提案: 「これらのコンポーネントが統合されたようです。新しい server-engineering に置き換えますか？」

### ECC 構造変更時

`skills/` が `modules/` にリネームされた場合:

- `/ecc-setup` コマンドのスキャン対象パスを更新するだけで対応可能
- 分類基準自体は変更不要

---

## 8. コマンドアーキテクチャ (v2)

### リファクタリングの理由

v1 の `/ecc-setup` は単一の 410 行ファイル（~10K tokens）に全サブコマンド、スキャンエンジン、分類基準、マニフェストスキーマを含んでいた。どのサブコマンドを実行しても全内容がシステムプロンプトとして読み込まれ、コンテキストウィンドウを圧迫していた。

問題点:

1. **Context 非効率**: `/ecc-setup bootstrap` 実行時に configure/evolve の仕様も全て読み込まれる
2. **圧縮不可**: コマンドプロンプトはシステムレベルで常駐し、会話の圧縮対象にならない
3. **言語非効率**: 日本語プロンプトは英語比で ~1.5-2 倍のトークンを消費

### 新ファイル構造

```text
.claude/commands/
  ecc-setup.md              — ルーター/ヘルプ（~25行, ~200 tokens）
  ecc-bootstrap.md          — Tier 0+1 フロー（~80行）
  ecc-configure.md          — Tier 2 フロー（~45行）
  ecc-evolve.md             — Tier 3 + 更新フロー（~55行）

docs/
  ecc-shared-spec.md        — 共有ランタイム仕様（~150行, Read ツール経由で遅延読み込み）
  ecc-extraction-analysis.md — 本ドキュメント（設計根拠）
```

### 遅延読み込みパターン

各サブコマンドファイルの冒頭に以下の指示を配置:

```text
Read docs/ecc-shared-spec.md for: path resolution, ECC detection, scan engine,
classification criteria, manifest schema, and operational notes.
```

これにより:

- **システムプロンプト**: サブコマンドファイルのみ（~800-1,500 tokens）
- **共有仕様**: Read ツール経由で assistant context に読み込まれる（圧縮可能）
- **ルーター**: ヘルプ表示のみ（~200 tokens）

### 言語分割方針

| コンテンツ種別 | 言語 | 理由 |
| --- | --- | --- |
| コマンド description frontmatter | 英語 | `/help` 表示用、英語で十分 |
| 指示・フロー記述 | 英語 | トークン効率、Claude の指示追従性 |
| 分類基準キーワード | 英語 | ECC の英語メタデータとマッチング |
| ユーザー向けメッセージ | 日本語 | ユーザー体験 |
| レポート内容 | 日本語 | ユーザー可読な成果物 |

制御方法: 各コマンドファイルに単一指示行 `All user-facing output must be in Japanese` を配置。

### コマンド名の変更

| v1 | v2 |
|---|---|
| `/ecc-setup bootstrap` | `/ecc-bootstrap` |
| `/ecc-setup configure` | `/ecc-configure` |
| `/ecc-setup evolve` | `/ecc-evolve` |
| `/ecc-setup` (ヘルプ) | `/ecc-setup` (ルーター、旧サブコマンド名でリダイレクト案内) |
