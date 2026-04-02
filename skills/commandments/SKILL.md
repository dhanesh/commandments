---
name: commandments
description: >-
  This skill should be used when the user runs "/commandments", asks to
  "evaluate the codebase against engineering commandments", "assess engineering
  maturity", "run a commandments assessment", "check codebase maturity levels",
  "how mature is this codebase", "engineering best practices audit",
  "code quality assessment against commandments", or "generate a commandments
  report". It evaluates the current repository against 10 Engineering
  Commandments using a 5-level maturity model and generates a detailed report
  with evidence-backed assessments and stack-specific actionable improvements.
argument-hint: "[--quick] [--focus=security]"
allowed-tools:
  - Read
  - Write
  - Grep
  - Glob
  - Bash
  - Agent
  - WebSearch
---

# Engineering Commandments Assessment

Evaluate the current repository against 10 Engineering Commandments, producing an evidence-backed maturity report with researched, prioritized actionable improvements.

## Pipeline Overview

Execute these phases sequentially, providing progress updates after each:

1. **Stack Detection** -- Identify the repository's tech stack
2. **Stack Research** -- WebSearch for stack-specific best practices
3. **Deep Evaluation** -- Assess each commandment with evidence
4. **Report Generation** -- Write/update `claudedocs/commandments-report.md`

IMPORTANT: Only READ codebase files for analysis. Never modify source code. The only file written is the report.

## Phase 1: Stack Detection

Scan for package manifests and configuration files to identify the tech stack:

```
Glob: package.json, requirements.txt, Pipfile, pyproject.toml, go.mod, Cargo.toml,
      pom.xml, build.gradle, Gemfile, composer.json, *.csproj, mix.exs, deno.json
Glob: Dockerfile, docker-compose.yml, .github/workflows/*, Makefile, Jenkinsfile
Glob: tsconfig.json, .eslintrc*, .prettierrc*, jest.config.*, vitest.config.*,
      webpack.config.*, vite.config.*, next.config.*, nuxt.config.*
```

Read each discovered manifest to extract:
- Languages and versions
- Frameworks (web, testing, ORM, etc.)
- Key dependencies and their purposes
- Build and deployment tooling

If no manifests found, analyze file extensions and directory structure as fallback. Clearly note "stack detected via heuristics" in the report.

## Phase 2: Stack Research

Using ONLY technology names (never internal code details), run WebSearch queries:

```
"[Framework] error handling best practices [current year]"
"[Framework] testing best practices [current year]"
"[Framework] observability logging monitoring [current year]"
"[Framework] security best practices OWASP [current year]"
```

Limit to 3-5 targeted searches for the primary stack components. Store findings for use in actionable recommendations.

## Phase 3: Deep Evaluation

For EACH of the 10 commandments, use the Agent tool (subagent_type: Explore) to perform deep codebase analysis. Launch agents in parallel clusters of 3-4 for efficiency.

Locate the bundled commandments reference for the full 5-level maturity criteria:
```
Glob: **/commandments.md
```
Read this file to load the maturity level definitions before assessing each commandment.

### Evidence Patterns Per Commandment

For each commandment, search for these specific evidence patterns:

#### 1. Design for Failure
- Grep: `try`, `catch`, `finally`, `rescue`, `except`, `recover`, `on_error`
- Grep: `retry`, `backoff`, `circuit.?breaker`, `fallback`, `timeout`
- Grep: `health.?check`, `readiness`, `liveness`
- Glob: `**/errors/**`, `**/exceptions/**`
- Check: Are errors caught with context or silently swallowed?
- Check: Do external calls have timeouts and retry logic?

#### 2. Keep It Simple
- Bash: Count average file length, nesting depth, function length
- Grep: Files with cyclomatic complexity indicators (deeply nested if/else/switch)
- Check: Are there overly abstract patterns (factories of factories, excessive inheritance)?
- Check: Dependency count relative to project size

#### 3. Test Early and Often
- Glob: `**/*.test.*`, `**/*.spec.*`, `**/test_*`, `**/*_test.*`, `**/tests/**`
- Glob: `**/__tests__/**`, `**/e2e/**`, `**/integration/**`
- Check: Test framework configuration present and configured
- Check: CI/CD pipeline includes test steps
- Bash: Ratio of test files to source files

#### 4. Build for Observability
- Grep: `logger`, `log\.`, `console\.log`, `logging`, `winston`, `pino`, `bunyan`, `slog`
- Grep: `metric`, `counter`, `histogram`, `gauge`, `tracing`, `span`, `opentelemetry`
- Grep: `correlation.?id`, `request.?id`, `trace.?id`
- Glob: `**/monitoring/**`, `**/dashboards/**`, `**/alerts/**`
- Check: Structured logging vs plain string logging

#### 5. Document Thy Intent
- Glob: `**/README.md`, `**/docs/**`, `**/adr/**`, `**/ADR/**`
- Grep: `@doc`, `@description`, `@param`, `@returns`, `"""`, `///`
- Check: Inline comments explain WHY, not WHAT
- Check: Architecture decision records present
- Check: API documentation (OpenAPI/Swagger specs)

#### 6. Automate Everything Repeatable
- Glob: `.github/workflows/**`, `.gitlab-ci.yml`, `Jenkinsfile`, `.circleci/**`
- Glob: `Dockerfile`, `docker-compose.*`, `terraform/**`, `*.tf`
- Glob: `Makefile`, `scripts/**`, `bin/**`
- Check: Infrastructure as Code present
- Check: Database migrations (not manual DDL)

#### 7. Secure by Design
- Grep: `sanitize`, `escape`, `validate`, `parameterize`, `prepared.?statement`
- Grep: `helmet`, `cors`, `csrf`, `rate.?limit`, `auth`
- Grep: `process\.env`, `os\.environ`, `env\(`, `dotenv`
- Glob: `.env.example`, `**/security/**`, `**/auth/**`
- Check: No hardcoded secrets (grep for patterns like API keys, passwords)
- Check: Input validation at boundaries

#### 8. Respect Data Consistency
- Grep: `transaction`, `atomic`, `lock`, `mutex`, `semaphore`
- Grep: `schema`, `validate`, `zod`, `joi`, `yup`, `pydantic`, `marshmallow`
- Grep: `idempoten`, `migration`, `constraint`, `foreign.?key`
- Check: External input validation present
- Check: Database migration files exist and are versioned

#### 9. Separate Concerns
- Check: Directory structure follows domain/feature boundaries
- Grep: `inject`, `interface`, `abstract`, `trait`, `protocol`
- Check: Module/package boundaries clear (index files, __init__.py)
- Check: Layered architecture (controllers/services/repositories or similar)
- Bash: Average file size and imports per file

#### 10. Plan for Scale
- Grep: `cache`, `redis`, `memcache`, `cdn`
- Grep: `async`, `await`, `queue`, `worker`, `job`, `celery`, `bull`, `sidekiq`
- Grep: `paginate`, `limit`, `offset`, `cursor`
- Grep: `pool`, `connection.?pool`, `thread.?pool`
- Check: Stateless service patterns
- Check: Load balancer or horizontal scaling configuration

### Maturity Level Assignment

For each commandment, compare evidence found against the 5-level criteria in `commandments.md`. Assign the HIGHEST level where ALL criteria are substantially met. When in doubt, assign the lower level and note what's missing.

Each assessment MUST include:
- **Level assigned** (1-5)
- **Evidence found** (specific file paths, patterns, counts)
- **Evidence missing** (what would be needed for the next level)

## Phase 4: Report Generation

### Report Location

Write to `claudedocs/commandments-report.md`. Create the `claudedocs/` directory if it doesn't exist.

### Existing Report Handling

If the report already exists:
1. Read it to extract the `## Assessment History` section
2. Generate the new report with updated assessments
3. Append the previous assessment summary to the history section

### Report Template

```markdown
# Engineering Commandments Assessment Report

**Repository:** [repo name from directory]
**Date:** [YYYY-MM-DD]
**Overall Maturity:** [average level, e.g., "Level 2.4 / 5"]

## Tech Stack

| Category | Technologies |
|----------|-------------|
| Languages | [detected] |
| Frameworks | [detected] |
| Testing | [detected] |
| CI/CD | [detected] |
| Infrastructure | [detected] |

## Maturity Summary

| # | Commandment | Level | Score |
|---|------------|-------|-------|
| 1 | Design for Failure | Level X | X/5 |
| 2 | Keep It Simple | Level X | X/5 |
| ... | ... | ... | ... |
| | **Overall** | | **X.X/5** |

## Detailed Assessments

### 1. Design for Failure - Level X/5

**Evidence Found:**
- [specific file paths and patterns found]
- [counts and metrics]

**Evidence Missing (for next level):**
- [what would be needed to reach Level X+1]

**Assessment Rationale:**
[Brief explanation of why this level was assigned]

[Repeat for all 10 commandments]

## Actionable Improvements (Prioritized by Impact)

### Priority 1: [Highest impact action]
**Commandment:** [which one]
**Current Level:** X -> **Target Level:** Y
**Effort:** Low/Medium/High
**Impact:** [why this matters most]

**Steps:**
1. [Specific, stack-aware step]
2. [Reference to best practice from WebSearch]

[Repeat for top 5-10 actions]

## Assessment History

| Date | Overall Score | Top Improvement | Notes |
|------|--------------|-----------------|-------|
| [previous dates and scores from existing report] |
| [current date] | [current score] | [biggest change] | [notes] |
```

### Actionable Recommendations

For each recommendation:
- Reference the SPECIFIC tech stack (e.g., "Add Express error-handling middleware" not "Add error handling")
- Include code patterns or library names from WebSearch findings
- Estimate effort (Low/Medium/High)
- Order by: impact score = (level gap x commandment criticality) / effort

Label any recommendation that falls back to general best practices (for unknown stacks) with: `[General Best Practice]`

## Flags

- `--quick`: Skip WebSearch research phase, use only codebase analysis
- `--focus=NAME`: Deep-dive into a single commandment (e.g., `--focus=security`)
