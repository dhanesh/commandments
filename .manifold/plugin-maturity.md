# plugin-maturity

## Outcome

Improve the engineering-commandments plugin from **Level 2.0 to Level 3.0+ overall maturity** by implementing the 6 prioritized gaps identified in the commandments assessment report (2026-04-03).

### Current State (from `claudedocs/commandments-report.md`)

| # | Commandment | Current | Target |
|---|------------|---------|--------|
| 1 | Design for Failure | 2 | 3 |
| 2 | Keep It Simple | 3 | 3 (maintain) |
| 3 | Test Early and Often | 1 | 2 |
| 4 | Build for Observability | 1 | 2 |
| 5 | Document Thy Intent | 3 | 4 |
| 6 | Automate Everything | 2 | 3 |
| 7 | Secure by Design | 2 | 3 |
| 8 | Data Consistency | 2 | 3 |
| 9 | Separate Concerns | 3 | 3 (maintain) |
| 10 | Plan for Scale | 1 | 2 |

### Improvement Priorities (from report)

1. **P1 (Low effort):** Add `set -euo pipefail` + `trap` to bash script → Commandments 1, 7
2. **P2 (Medium effort):** Add bats-core automated tests → Commandment 3
3. **P3 (Low effort):** Add diagnostic logging to hook script → Commandment 4
4. **P4 (Medium effort):** Add CI/CD pipeline (GitHub Actions) → Commandment 6
5. **P5 (Low effort):** Add input validation to bash script → Commandments 7, 8
6. **P6 (Low effort):** Add ADRs and CHANGELOG → Commandment 5

---

## Constraints

### Business

#### B1: Zero External Runtime Dependencies

The plugin must never introduce external runtime dependencies (npm packages, pip, brew, etc.). Only built-in bash utilities and Claude Code tools are permitted.

> **Rationale:** Zero-dependency is the plugin's core value proposition. It works everywhere Claude Code runs without setup. Adding dependencies would create installation friction, version conflicts, and a maintenance burden disproportionate to this plugin's scope.

#### B2: Achieve Level 3.0+ Overall Maturity

The overall commandments maturity score must reach 3.0 or higher (currently 2.0/5) after all improvements are implemented.

> **Rationale:** The plugin *enforces* engineering commandments on other codebases. Practicing what it preaches at Level 3+ is the minimum credibility threshold. Target is deterministic: 3.0/5 ceiling.

#### B3: Maintain Current Simplicity

Improvements must not degrade the existing Level 3 scores for "Keep It Simple" (Commandment 2) and "Separate Concerns" (Commandment 9).

> **Rationale:** The plugin's elegance is a feature. Adding CI, tests, and docs must not bloat the core codebase or blur the clean separation between skills, hooks, and config. If scaffolding grows larger than the plugin itself, we've failed.

---

### Technical

#### T1: Bash Strict Mode Required

The hook script (`hooks/scripts/inject-claude-md.sh`) must use `set -euo pipefail` as the first executable line after the shebang.

> **Rationale:** Industry standard for production bash. `set -e` exits on error, `set -u` catches unset variables, `set -o pipefail` catches pipeline failures. Without these, errors propagate silently -- the exact anti-pattern Commandment 1 (Design for Failure) targets.

#### T2: Hook Execution Within 5-Second Timeout

The hook script must complete execution within the 5-second timeout already configured in `hooks.json`. No changes may increase execution time beyond this boundary.

> **Rationale:** The hook runs on every SessionStart. Exceeding the timeout would either delay session startup or cause the hook to be killed mid-write, potentially corrupting CLAUDE.md. Threshold: deterministic ceiling of 5000ms.

#### T3: Bats-Core Test Framework

Automated tests must use [bats-core](https://github.com/bats-core/bats-core) as the bash testing framework, installed as a dev-time dependency (not runtime).

> **Rationale:** Bats-core is the standard testing framework for bash scripts. It provides TAP-compliant output, setup/teardown fixtures, and integrates with CI runners. Dev-time dependency is acceptable per B1 (zero *runtime* deps).

#### T4: GitHub Actions CI/CD with Automated Releases

CI/CD pipeline via GitHub Actions must include: ShellCheck linting, JSON schema validation, bats-core test execution. Additionally, automated version tagging and release creation on merge to main.

> **Rationale:** Automates all quality gates (Commandment 6) and ensures every change is validated before merge. Automated releases reduce manual overhead and ensure consistent versioning.

#### T5: JSON Config Schema Validation

All JSON configuration files (`plugin.json`, `hooks.json`, `marketplace.json`) must be validated against their respective schemas in CI.

> **Rationale:** Invalid JSON configs fail silently at runtime. Schema validation in CI catches structural errors before they reach users, addressing Commandment 8 (Data Consistency).

#### T6: Hook Regression Integration Tests

Every change to the hook script must have corresponding integration tests that verify: (a) clean injection into a fresh CLAUDE.md, (b) idempotent re-injection, (c) graceful handling of missing/unset env vars, (d) no corruption of existing CLAUDE.md content.

> **Rationale:** *Source: pre-mortem.* The primary failure scenario is a hook regression breaking Claude Code sessions for all users. Integration tests specifically targeting session startup behavior are the primary defense.

---

### User Experience

#### U1: Silent by Default, Debug on Demand

The hook script must produce zero stdout/stderr output during normal operation. Verbose diagnostic output is available only when `DEBUG=1` environment variable is set.

> **Rationale:** The hook runs on every session start. Any output clutters the user's terminal and degrades the Claude Code experience. Developers troubleshooting the plugin can opt in with `DEBUG=1`.

#### U2: Errors Always to Stderr

When the hook script encounters an error (validation failure, write failure, missing paths), it must log a clear, actionable error message to stderr regardless of DEBUG setting.

> **Rationale:** Silent failures are the worst outcome. Errors must always be visible so users can diagnose and report issues. Normal operation is silent; abnormal operation is loud.

#### U3: Hook Must Never Break Sessions

The hook script must exit 0 (success) even when it encounters errors. It must never cause a Claude Code session to fail to start.

> **Rationale:** *Source: pre-mortem.* This is the highest-risk scenario: a hardened script that introduces a regression breaking all sessions. The script's purpose is convenience, not necessity -- it must degrade gracefully, never fatally. All validation failures should log and exit 0, not exit 1.

---

### Security

#### S1: No Hardcoded Secrets

No file in the repository may contain hardcoded secrets, API keys, tokens, or credentials.

> **Rationale:** Basic security hygiene. The plugin is intended for public distribution. Any secret in the repo is immediately compromised.

#### S2: Strict Environment Variable Validation

Before using `$HOME`, `$CLAUDE_PLUGIN_ROOT`, or any derived paths, the script must validate they are: (a) set and non-empty, (b) pointing to existing directories.

> **Rationale:** Unvalidated environment variables can lead to writes to unexpected locations (e.g., `/$EMPTY_VAR/.claude/CLAUDE.md` → `/.claude/CLAUDE.md`). Strict validation prevents path traversal and accidental writes outside user space.

#### S3: No Writes Outside Intended Paths

The script must only write to `$HOME/.claude/CLAUDE.md`. It must not create files, modify files, or write to any other location.

> **Rationale:** Principle of least privilege. The script's purpose is singular (inject a reference into CLAUDE.md). Any write beyond that scope is a bug or a security concern.

---

### Operational

#### O1: CI Pipeline on Every Push and PR

The GitHub Actions workflow must trigger on every push to any branch and every pull request to main.

> **Rationale:** Continuous validation prevents regressions from reaching main. PRs cannot be merged without passing all quality gates.

#### O2: ShellCheck Zero Warnings

All bash scripts must pass ShellCheck with zero warnings (no `# shellcheck disable` directives unless individually justified with comments).

> **Rationale:** ShellCheck catches subtle bash bugs (unquoted variables, incorrect test syntax, useless cat, etc.) that are easy to miss in review. Zero-warning policy ensures consistent quality.

#### O3: Full Documentation Suite

The plugin must include: ADRs (minimum 3 key decisions), CHANGELOG.md, CONTRIBUTING.md, and a `docs/` directory with a developer guide.

> **Rationale:** The plugin enforces documentation standards (Commandment 5) on other codebases. A full docs suite demonstrates maturity and enables external contributors. Target Level 4 for Documentation commandment.

#### O4: Automated Version Tagging and Releases

On merge to main, CI must automatically create a git tag and GitHub release with changelog entries.

> **Rationale:** Manual release processes are error-prone and easily forgotten. Automated releases ensure every meaningful change is versioned and discoverable.

---

## Tensions

### TN1: Strict Mode vs Session Safety

`set -euo pipefail` (T1) makes the script exit immediately on any error. But U3 requires the hook to *never* break sessions -- it must always exit 0.

**Type:** Trade-off (physical contradiction -- same script must fail-fast AND never fail)

**TRIZ Classification:** Physical contradiction. Parameter: script exit behavior. Principles: P1 (Segmentation) -- separate strict-mode internals from top-level exit behavior; P35 (Parameter Change) -- transform exit code at the boundary.

> **Resolution:** (Option A: Trap wrapper) Wrap the script body in a `main()` function with `set -euo pipefail` active. A top-level `trap '... exit 0' ERR` catches any error, logs it to stderr (satisfying U2), and exits 0 (satisfying U3). Strict mode catches bugs during development and CI; production always exits clean.

**Propagation:** No constraints tightened or violated. SAFE.

### TN2: Full Docs Suite vs Simplicity

O3 (full documentation suite with ADRs, CHANGELOG, CONTRIBUTING) adds files and structure to a 772-line plugin. B3 (maintain simplicity) requires that improvements don't bloat the codebase.

**Type:** Trade-off

> **Resolution:** (Option A: Lightweight docs) Consolidate all ADRs into a single `docs/DECISIONS.md` file instead of separate numbered files. CHANGELOG.md and CONTRIBUTING.md at repo root. No `docs/` subdirectory beyond DECISIONS.md. This satisfies the documentation commandment without creating more doc files than source files.

**Propagation:** O3 TIGHTENED -- lightweight format accepted instead of full directory structure, but still meets Level 4 criteria. PROCEED WITH AWARENESS.

### TN3: Bats-Core Tests vs Zero Dependencies

T3 (bats-core test framework) requires an external tool, but B1 (zero external runtime dependencies) forbids external deps. The interview clarified "dev-time deps OK" but the mechanism matters.

**Type:** Resource tension

> **Resolution:** (Option A: Git submodule) Add bats-core as a git submodule at `tests/bats/`. No package manager needed. CI clones with `--recurse-submodules`. The submodule is dev-time only -- it's not loaded at runtime by the plugin.

**Propagation:** B3 TIGHTENED slightly (adds `tests/bats/` submodule directory to repo structure). B1 satisfied -- zero runtime deps. PROCEED WITH AWARENESS.

### TN4: Automated Releases vs Release Control

O4 (automated version tagging and releases) depends on T4 (CI pipeline), but the trigger mechanism determines how much control the maintainer has over what becomes a release.

**Type:** Hidden dependency

> **Resolution:** (Option B: Every merge to main) Fully automated -- every merge to main auto-bumps the version based on conventional commit prefixes (`feat:`, `fix:`, `chore:`) and creates a GitHub release with generated changelog. Non-main branches do not trigger releases.

**Propagation:** B3 TIGHTENED slightly (adds release automation config to CI workflow). O4 and T4 satisfied. SAFE.

---

## Required Truths

### RT-1: Hook Script Handles Errors Safely

The bash script uses `set -euo pipefail` with a top-level ERR trap that logs errors and exits 0. Script body is wrapped in a `main()` function.

**Gap:** Current script has no strict mode, no trap, no main() wrapper.

**Sub-truths:**
- RT-1.1: `set -euo pipefail` present after shebang [PRIMITIVE]
- RT-1.2: ERR trap catches failures and exits 0 [PRIMITIVE]
- RT-1.3: `main()` function wraps script body [PRIMITIVE]

### RT-2: Automated Tests Exist and Pass

Bats-core integration tests cover the 4 critical hook scenarios: fresh injection, idempotent re-injection, missing env vars, and no corruption of existing content. JSON validation tests verify config file structure.

**Gap:** No tests exist. No test framework installed.

**Sub-truths:**
- RT-2.1: bats-core available locally [NOT_SATISFIED]
  - RT-2.1.1: git submodule at `tests/bats/` [PRIMITIVE]
- RT-2.2: Integration tests cover 4 hook scenarios [PRIMITIVE]
- RT-2.3: JSON validation tests for config files [PRIMITIVE]

### RT-3: Hook Produces Diagnostic Output

Script includes `log_error` (always to stderr) and `log_debug` (gated by `DEBUG=1`) functions. Normal execution produces zero output.

**Gap:** Script currently produces no output at all. Need logging functions added.

**Sub-truths:**
- RT-3.1: `log_error` function writes to stderr [PRIMITIVE]
- RT-3.2: `log_debug` function gated by `DEBUG=1` [PRIMITIVE]
- RT-3.3: Normal execution produces zero output [SATISFIED -- already true]

### RT-4: CI/CD Pipeline Validates and Releases (BINDING CONSTRAINT)

GitHub Actions workflow runs ShellCheck, JSON validation, and bats tests on every push/PR. Auto-release on merge to main using conventional commits.

**Gap:** No CI/CD pipeline exists. This is the highest-complexity required truth and depends on RT-2 (tests) being satisfied first.

**Sub-truths:**
- RT-4.1: GitHub Actions workflow file exists [PRIMITIVE]
- RT-4.2: ShellCheck runs in CI [NOT_SATISFIED]
  - RT-4.2.1: All scripts pass ShellCheck locally first [PRIMITIVE]
- RT-4.3: Bats tests run in CI [NOT_SATISFIED]
  - RT-4.3.1: CI clones with `--recurse-submodules` [PRIMITIVE]
- RT-4.4: JSON schema validation in CI [PRIMITIVE]
- RT-4.5: Auto-release on main merge via conventional commits [PRIMITIVE]

### RT-5: Environment Variables Validated Before Use

Script validates `$HOME`, `$CLAUDE_PLUGIN_ROOT`, and `$SKILL_PATH` are set, non-empty, and point to existing paths before using them.

**Gap:** Current script uses these variables without any validation.

**Sub-truths:**
- RT-5.1: `$HOME` validated as set and existing directory [PRIMITIVE]
- RT-5.2: `$CLAUDE_PLUGIN_ROOT` validated as set and existing directory [PRIMITIVE]
- RT-5.3: `$SKILL_PATH` validated as existing file [PRIMITIVE]

### RT-6: Design Decisions Documented

`docs/DECISIONS.md` contains at least 3 ADRs (SessionStart hook, two-skill architecture, @-injection pattern). `CHANGELOG.md` and `CONTRIBUTING.md` exist at repo root.

**Gap:** None of these files exist.

**Sub-truths:**
- RT-6.1: `docs/DECISIONS.md` with ≥3 ADRs [PRIMITIVE]
- RT-6.2: `CHANGELOG.md` at repo root [PRIMITIVE]
- RT-6.3: `CONTRIBUTING.md` at repo root [PRIMITIVE]

---

## Binding Constraint

**RT-4 (CI/CD Pipeline)** is the binding constraint:
- Highest complexity of all required truths
- Covers the most constraints (T4, T5, O1, O2, O4)
- Achieving C6 Level 4 depends entirely on this
- Depends on RT-2 (tests) which depends on RT-2.1 (bats submodule)
- If RT-4 is not satisfied, the maturity score cannot reach the target regardless of other improvements

---

## Solution Space

### Option A: Script-First Bottom-Up ← Recommended

Execute in 4 sequential phases, each building on the previous:

**Phase 1:** Harden `inject-claude-md.sh` (RT-1, RT-3, RT-5)
**Phase 2:** Add bats-core tests (RT-2)
**Phase 3:** GitHub Actions CI/CD + auto-release (RT-4)
**Phase 4:** Documentation suite (RT-6)

- **Satisfies:** All 6 required truths
- **Complexity:** Medium
- **Reversibility:** TWO_WAY (all steps independently reversible)
- **Rationale:** Each phase builds on verified work. Tests verify the hardened script. CI runs verified tests. Docs describe the completed system.

### Option B: Parallel Agents

Launch 4 agents simultaneously for maximum speed.

- **Satisfies:** All 6 required truths
- **Complexity:** Medium
- **Reversibility:** TWO_WAY
- **Risk:** Agent writing tests may target old script signature before hardening agent finishes, causing integration failures.

### Option C: CI-First Top-Down

Set up CI skeleton first, then add content for it to validate.

- **Satisfies:** All 6 required truths
- **Complexity:** Medium
- **Reversibility:** TWO_WAY
- **Drawback:** CI initially has nothing meaningful to validate. Artificial early commits.
