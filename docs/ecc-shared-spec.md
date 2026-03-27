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
3. If not found, stop immediately and display:

```
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
|---|---|---|
| Skills | `$ECC_ROOT/skills/*/SKILL.md` | YAML frontmatter (name, description) + `## When to Activate` section |
| Skills (agents dir) | `$ECC_ROOT/.agents/skills/*/SKILL.md` | Same as above. `skills/` takes priority on duplicates |
| Agents | `$ECC_ROOT/agents/*.md` | YAML frontmatter (name, description, model) or body intro |
| Rules | `$ECC_ROOT/rules/{common,typescript,python,...}/*.md` | `paths:` frontmatter + body scope |
| Commands | `$ECC_ROOT/commands/*.md` | `description:` frontmatter or body intro |

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

#### Tier 3: Continuous (during development)

- **Pattern Extraction**: learn, pattern extraction, session analysis
- **Continuous Learning**: continuous learning, instinct, confidence scoring, skill evolution
- **Rules Distillation**: rules distill, principle extraction
- **Context Management**: context budget, compaction, token optimization
- **Skill Audit**: skill stocktake, skill compliance, skill health

### Classification Rules

1. Components spanning multiple tiers → classify to the **earliest** (lowest number) tier
2. `rules/common/` → **always Tier 1**
3. Components excluded by tech stack filter are still included in classification results for report completeness

---

## Tech Stack Filter

Based on manifest `tech_stack`:

1. **INCLUDE**: Components matching user's selected languages/frameworks
2. **EXCLUDE**: Components **specific to** unselected languages/frameworks
   - Example: If Python not selected, exclude `python-patterns` but keep generic `backend-patterns`
3. **Domain Skills**: Supply-chain, media, social, investor, content, etc. → exclude candidates
   - Confirm with user: 「これらは無関係と判断しましたが、必要なものはありますか？」

---

## Install Destinations

| Type | Destination |
|---|---|
| Skills | `$PROJECT_ROOT/.claude/skills/<name>/` |
| Rules | `$PROJECT_ROOT/.claude/rules/<scope>/<topic>.md` |
| Agents | `$PROJECT_ROOT/.agents/<name>.md` |
| Commands | `$PROJECT_ROOT/.claude/commands/<name>.md` |

Create directories with `mkdir -p` as needed.

---

## Manifest Schema (`ecc-manifest.yaml`)

```yaml
version: 1

project:
  name: "<project name>"
  root: "<PROJECT_ROOT absolute path>"
  tech_stack:
    languages: []       # Set during bootstrap (user selection)
    frameworks: []      # Set during bootstrap (user selection)

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
#   - type: "skill" | "agent" | "rule" | "command"
#     name: "<component name>"
#     source: "<relative path from ECC_ROOT>"
#     destination: "<relative path from PROJECT_ROOT>"
#     tier: 0 | 1 | 2 | 3
#     domain: "<knowledge domain>"
#     reason: "<selection reason>"
#     installed_at: "<ISO 8601>"

excluded: []
# Each entry:
#   - type: "skill" | "agent" | "rule" | "command"
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
