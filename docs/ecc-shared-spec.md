# ECC Shared Specification

Runtime reference for `/ecc-init`, `/ecc-bootstrap`, `/ecc-configure`, `/ecc-evolve` commands.
This file is read on-demand by each command — do not load preemptively.

---

## Path Resolution

Resolve all paths dynamically. Never hardcode absolute paths.

```text
PROJECT_ROOT:   Current working directory
PROJECT_CLAUDE: $PROJECT_ROOT/.claude/
MANIFEST_PATH:  $PROJECT_ROOT/ecc-manifest.yaml
REPORT_DIR:     $PROJECT_ROOT/docs/ecc-reports/
TEMPLATES_DIR:  $PROJECT_ROOT/docs/ecc-templates/
```

### ECC_ROOT Resolution (priority order)

1. **Environment variable**: If `$ECC_ROOT` is set and the directory exists, use it
2. **Manifest**: If `$MANIFEST_PATH` exists and `ecc.source` is set, use it
3. **Default**: `$PROJECT_ROOT/../everything-claude-code/`
4. **Error**: If none resolve to a valid directory, display error message below

## ECC Detection

1. Check that `$ECC_ROOT` exists
2. Verify `skills/` and `agents/` directories exist inside it
3. Check `mcp-configs/` existence (optional — warn if missing, do not stop)
4. If `skills/` or `agents/` not found, stop immediately and display:

```text
❌ ECC（Everything Claude Code）が見つかりません。

以下のいずれかの方法で設定してください:

  方法1: 環境変数を設定
    export ECC_ROOT=/path/to/everything-claude-code

  方法2: プロジェクトと同じ階層にクローン
    cd $PROJECT_ROOT/..
    git clone https://github.com/affaan-m/everything-claude-code.git

期待するディレクトリ構成:
  <workspace>/
  ├── everything-claude-code/   ← ECC
  └── <your-project>/           ← 現在のプロジェクト
```

---

## Scan Engine

### Scan Targets

| Type | Path | What to Read |
| --- | --- | --- |
| Skills | `$ECC_ROOT/skills/*/SKILL.md` | YAML frontmatter (name, description) + `## When to Activate` section |
| Skills (agents dir) | `$ECC_ROOT/.agents/skills/*/SKILL.md` | Same as above. `skills/` takes priority on duplicates |
| Skills (openai.yaml) | `$ECC_ROOT/.agents/skills/*/agents/openai.yaml` | display_name, short_description (supplement to SKILL.md) |
| Agents | `$ECC_ROOT/agents/*.md` | YAML frontmatter (name, description, model, tools) |
| Rules | `$ECC_ROOT/rules/{common,typescript,python,...}/*.md` | `paths:` frontmatter + body scope |
| Commands | `$ECC_ROOT/commands/*.md` | `description:` frontmatter or body intro |
| MCP | `$ECC_ROOT/mcp-configs/mcp-servers.json` | JSON: server name, command, args, env, description |

MCP scan: Parse the single JSON file. Each key under `mcpServers` is treated as one component. The `env` field indicates API key requirements.

### Classification Criteria

Classify each component by matching its `description` and body content against knowledge domain keywords. **Use domain-based criteria, not hardcoded component name lists.**

#### Tier 0: Safety

Keywords: destructive operation prevention, permission guard, safety policy, settings.json safety

#### Tier 1: Design Knowledge (needed before cc-sdd)

- **Architecture**: architecture, system design, modularity, scalability, layering, dependencies
- **API Design**: API design, REST, resource naming, response format, pagination, versioning, status codes
- **Data Design**: schema design, database patterns, indexing, normalization, migration safety
- **Security Design**: security design, authentication architecture, OWASP, secrets management, authorization
- **Performance Design**: caching strategies, N+1 prevention, scaling patterns, performance optimization
- **Decision Records**: ADR, architecture decision record, tradeoff analysis
- **Frontend Design**: component composition, state management patterns, design system, design tokens
- **Backend Design**: service layer, repository pattern, middleware patterns, dependency injection
- **Requirements**: requirements validation, MVP definition, product thinking, anti-goals
- **Workflow Foundation**: research-first, plan-first, git workflow, coding style (immutability)
- **Common Rules**: `rules/common/` directory — always Tier 1 regardless of content

#### Tier 2: Implementation (after cc-sdd design finalized)

- **Language-specific**: language-specific coding style, type checking, linting, formatting
- **Testing**: TDD, E2E testing, test coverage, pytest, Playwright, unit testing
- **Code Review**: code review, quality check, pull request review
- **Build/Deploy**: build fix, deployment, CI/CD, Docker, container
- **Framework Patterns**: framework-specific implementation patterns (Next.js, NestJS, Django, etc.)
- **Language Idioms**: Pythonic idioms, TypeScript patterns, language-specific best practices
- **Dev Tools**: MCP server patterns, documentation lookup
- **MCP Integration**: MCP servers, external tool integration (default tier for MCP components)

#### Tier 3: Continuous (during development)

- **Pattern Extraction**: learn, pattern extraction, session analysis
- **Continuous Learning**: continuous learning, instinct, confidence scoring, skill evolution
- **Rules Distillation**: rules distill, principle extraction
- **Context Management**: context budget, compaction, token optimization
- **Skill Audit**: skill stocktake, skill compliance, skill health

### Classification Rules

1. Components spanning multiple tiers → classify to the **earliest** (lowest number) tier
2. `rules/common/` → **always Tier 1**
3. Components excluded by scoring are still included in classification results for report completeness

---

## Component Classification Keywords

Used by the Scoring Algorithm to determine component relevance to the user's project.

### Language-Specific Keywords

```yaml
typescript: [typescript, tsx, ts, node.js, javascript, js, jsx]
python: [python, pip, django, flask, fastapi, pytest, pep]
rust: [rust, cargo, crate, borrow checker, lifetime]
golang: [golang, go module, goroutine, go vet]
kotlin: [kotlin, gradle, android, kmp, coroutine]
swift: [swift, swiftui, xcode, ios, macos]
cpp: [c++, cpp, cmake, header, pointer]
java: [java, spring, maven, jpa, jvm]
php: [php, laravel, composer, blade]
perl: [perl, cpan]
csharp: [c#, csharp, dotnet, .net, nuget]
```

### Framework-Specific Keywords

```yaml
nextjs: [next.js, nextjs, app router, turbopack, server components]
django: [django, django rest]
fastapi: [fastapi]
springboot: [spring boot, springboot]
laravel: [laravel, eloquent]
express: [express.js, express middleware]
nestjs: [nestjs, nest.js]
flutter: [flutter, dart]
react: [react, jsx, hooks]
vue: [vue, nuxt, vuex]
```

### Tool-Specific Keywords

```yaml
docker: [docker, container, dockerfile, compose]
postgres: [postgres, postgresql, sql database]
playwright: [playwright, browser testing]
supabase: [supabase]
cloudflare: [cloudflare, workers, wrangler]
```

### Domain-Specific Keywords

```yaml
business: [investor, pitch, outreach, market research, strategic]
content: [article, crosspost, social media, content engine, newsletter]
media: [video, image, fal-ai, media generation, audio]
```

---

## Scoring Algorithm

For each component, calculate a relevance score by matching its `description` (and `short_description` from openai.yaml if available) against the Classification Keywords above.

### Scoring Rules

Evaluate top to bottom. First match wins per keyword group:

1. Language match AND in `tech_stack.languages` → **+10**
2. Language match AND NOT in `tech_stack.languages` → **-100** (auto-exclude)
3. Framework match AND in `tech_stack.frameworks` → **+10**
4. Framework match AND NOT in `tech_stack.frameworks` → **-100** (auto-exclude)
5. Tool match (tool_specific keywords) → **+2**
6. Tool match AND tool in Project Type Bonus list → **+5** (overrides rule 5)
7. Domain match (domain_specific keywords) → **0** (confirm with user)
8. NO match to any keyword list → **+5** (UNIVERSAL)

### Special Rules

- `rules/common/` → always UNIVERSAL (+5), always Tier 1
- `rules/<language>/` → language match rules apply (rule 1 or 2)
- Multiple keyword group matches → scores are additive (e.g., language +10 AND tool +2 = +12)

### Project Type

```yaml
project_types:
  frontend: "SPA / SSR / Static サイト"
  backend: "API / CLI / Worker"
  fullstack: "Frontend + Backend"
  library: "ライブラリ / パッケージ"
  infrastructure: "Infrastructure / DevOps"
  data: "Data / ML Pipeline"
```

Set during bootstrap (Step 3b Q0). Stored in manifest `project.type`.

### Project Type Bonus

When a component matches a tool_specific keyword AND the tool appears in the bonus list for the user's project type, apply **+3 bonus** on top of the base score.

| Project Type | Bonus Targets |
| --- | --- |
| frontend | playwright, design-system, frontend-patterns, frontend-slides |
| backend | docker, postgres, api-design, database-migrations, deployment-patterns |
| fullstack | playwright, docker, postgres, api-design, frontend-patterns, backend-patterns, database-migrations, deployment-patterns, e2e-testing, security-review, design-system |
| library | coding-standards, verification-loop |
| infrastructure | docker, deployment-patterns, cloudflare-* |
| data | postgres, cost-aware-llm-pipeline |

Note: fullstack covers the full lifecycle (requirements → deployment → operations), so bonus targets are broadly set.

### Display Thresholds

| Score | Label | 意味 |
| --- | --- | --- |
| 8+ | ⭐⭐⭐ 強く推薦 | Tech Stack 直接一致 |
| 3+ | ⭐⭐ 推薦 | 汎用 or Project Type 一致 |
| 1+ | ⭐ 任意 | ツール特化（あると便利） |
| 0 | 📦 確認必要 | ドメイン特化（要ユーザー確認） |
| <0 | ❌ 除外 | 言語/FW 不一致（非表示） |

---

## Phase Presentation

Within each command (bootstrap, configure, evolve), present scored components grouped by component type in 5 phases:

| Phase | Type | 説明 |
| --- | --- | --- |
| A | Skills | 設計知識・パターン |
| B | Agents | 専門レビュアー・ビルダー |
| C | Rules | コーディング規約 |
| D | Commands | ワークフロー |
| E | MCP Servers | 外部ツール連携 |

### Display Format (per phase)

Group by score threshold, sorted by score descending within each group:

```markdown
**Phase X: (Phase Name)**

- ⭐⭐⭐ 強く推薦 → `| # | Component | 説明 | 根拠 |`
- ⭐⭐ 推薦 → same table format
- ⭐ 任意 → same table format
- 📦 ドメイン特化（確認が必要）→ same table format
```

### User Selection Syntax

Per phase, prompt user with:

「Phase X: (Phase Name) — インストールするコンポーネントを選択してください:」

- 番号指定: `1,2,3,5-8`
- `recommended` — ⭐⭐⭐ + ⭐⭐ を全選択
- `all` — 全てインストール
- `info <番号>` — 詳細を表示
- `skip` — このフェーズをスキップ

### Empty Phase Handling

Skip phases with 0 components silently (do not display empty headers).

### Info Detail Display

When user selects `info N`, show:

- **Skills**: SKILL.md description + "When to Activate" section + openai.yaml short_description
- **Agents**: description + model + tools list
- **Commands**: description
- **Rules**: file list in the directory
- **MCP**: command, description, required env vars (from `env` field)

---

## Install Destinations

| Type | Destination |
| --- | --- |
| Skills | `$PROJECT_ROOT/.claude/skills/<name>/` |
| Rules | `$PROJECT_ROOT/.claude/rules/<scope>/<topic>.md` |
| Agents | `$PROJECT_ROOT/.agents/<name>.md` |
| Commands | `$PROJECT_ROOT/.claude/commands/<name>.md` |
| MCP | `$PROJECT_CLAUDE/settings.json` → `mcpServers.<name>` |

Create directories with `mkdir -p` as needed.

MCP install: Read existing `settings.json` as JSON, add/update `mcpServers.<server_name>` for each approved MCP server, write back formatted JSON. Never overwrite the entire file — preserve all other settings. For servers with `env` field containing API keys, display setup instructions to the user.

---

## Manifest Schema (`ecc-manifest.yaml`)

```yaml
version: 1

project:
  name: "<project name>"
  type: "<project type>"          # frontend | backend | fullstack | library | infrastructure | data
  root: "<PROJECT_ROOT absolute path>"
  tech_stack:
    languages: []       # Set during bootstrap (user selection)
    frameworks: []      # Set during bootstrap (user selection)
    tools: []           # Set during bootstrap (docker, postgres, etc.)

ecc:
  source: "<ECC_ROOT absolute path>"
  commit_hash: "<git rev-parse HEAD result>"
  pinned_version: null  # Set to git tag to lock. /ecc-evolve warns before updating past this.
  last_sync: "<ISO 8601 timestamp>"

tiers:
  tier0:
    installed_at: null  # Set when bootstrap completes
    settings_modified: false
  tier1:
    installed_at: null
  tier2:
    installed_at: null
  tier3:
    installed_at: null

installed: []
# Each entry:
#   - type: "skill" | "agent" | "rule" | "command" | "mcp"
#     name: "<component name>"
#     source: "<relative path from ECC_ROOT>"
#     destination: "<relative path from PROJECT_ROOT>"
#     tier: 0 | 1 | 2 | 3
#     domain: "<knowledge domain>"
#     score: <number>
#     reason: "<selection reason>"
#     installed_at: "<ISO 8601>"

excluded: []
# Each entry:
#   - type: "skill" | "agent" | "rule" | "command" | "mcp"
#     name: "<component name>"
#     reason: "<exclusion reason>"

scans: []
# Each entry:
#   - date: "<ISO 8601>"
#     subcommand: "bootstrap" | "configure" | "evolve"
#     total_scanned: <number>
#     installed_count: <number>
#     report_path: "<report file path>"
```

---

## Operational Notes

- **Project-scoped only**: Never use `~/.claude/` (user-level). All installs go to `$PROJECT_ROOT/.claude/`.
- **Preserve rule subdirectory structure**: Copy `common/`, `typescript/`, `python/` as-is. Flattening causes filename collisions (e.g., `security.md`, `coding-style.md`).
- **Confirm before overwriting**: Always ask user before overwriting existing files, especially `.claude/settings.json`.
- **Read-only on ECC**: Never modify files inside the ECC repository. Only modify copies at the destination.
- **Version pinning**: If `ecc.pinned_version` is set in the manifest, `/ecc-evolve` warns before applying updates past the pinned commit.
- **Template path**: `/ecc-init` reads templates from `$TEMPLATES_DIR` (installed by `install.sh`).
- **MCP API keys**: MCP servers may require API keys. Check the `env` field in `mcp-servers.json` and warn the user about required environment variables with setup instructions.
- **MCP config merge**: Read existing `settings.json` as JSON, add/update the `mcpServers` key, write back. Preserve all other settings.
