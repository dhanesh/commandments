# Architecture Decisions

Lightweight ADR log for the engineering-commandments plugin. Each decision records what was chosen, why, and what alternatives were considered.

---

## ADR-001: SessionStart Hook for Always-Active Enforcement

**Date:** 2026-04-03
**Status:** Accepted

**Context:** The enforcement skill needs to be active during all development activities without requiring users to manually invoke it. Claude Code skills are only loaded when referenced in `CLAUDE.md` or invoked explicitly.

**Decision:** Use a `SessionStart` hook that runs a bash script to inject an `@`-reference to the enforcement skill into the user's global `~/.claude/CLAUDE.md`.

**Alternatives considered:**
- **Manual installation instructions** -- Requires user action, easy to forget, no guarantee of adoption.
- **Plugin-level auto-loading** -- Claude Code's plugin system doesn't auto-load skills into the session context without a `CLAUDE.md` reference.
- **Project-level CLAUDE.md** -- Would only work per-project, not globally across all repositories.

**Consequences:**
- The script modifies a user-owned file (`~/.claude/CLAUDE.md`), which requires careful idempotency and error handling.
- The script must never break Claude Code sessions (see ADR-003).
- Users can remove the reference manually if they don't want enforcement.

---

## ADR-002: Two-Skill Architecture (Assess vs Enforce)

**Date:** 2026-04-03
**Status:** Accepted

**Context:** The plugin needs to both (a) evaluate codebases against the 10 commandments and (b) enforce the commandments during active development. These are fundamentally different workflows.

**Decision:** Separate into two distinct skills:
- `commandments` -- On-demand assessment that generates a maturity report. User-triggered via `/commandments`.
- `enforce-commandments` -- Always-active enforcement that applies commandment principles during code writing, planning, and review. Loaded via SessionStart hook.

**Alternatives considered:**
- **Single skill** -- One skill that handles both assessment and enforcement. Rejected because the trigger patterns, tool requirements, and output formats differ significantly. A combined skill would be harder to maintain and would bloat the always-active context.
- **Three+ skills** -- Separate skills per gate (specification, implementation, review). Rejected as over-engineering; the gate checklists work well as references within a single enforcement skill.

**Consequences:**
- Clean separation of concerns: each skill has one job.
- The enforcement skill can be lightweight (loaded every session) while the assessment skill can be comprehensive (loaded on demand).
- Gate checklists live as references under the enforcement skill, not as separate skills.

---

## ADR-003: Fail-Safe Hook Script (Trap Wrapper Pattern)

**Date:** 2026-04-03
**Status:** Accepted

**Context:** The hook script runs on every Claude Code session start. If it fails with a non-zero exit code, it could break sessions for all users. However, we also want `set -euo pipefail` for development safety.

**Decision:** Use a trap wrapper pattern: `set -euo pipefail` is active for internal logic, but a top-level `trap '... exit 0' ERR` catches any error, logs it to stderr, and always exits 0.

**Alternatives considered:**
- **No strict mode** -- Manual error checks after every command. Loses the safety net that catches unexpected failures during development.
- **Conditional strict mode** -- Only enable strict mode in CI. Production script would miss unset variable bugs.
- **Accept the risk** -- Let the script exit non-zero on errors. Rejected because the pre-mortem analysis identified "hook breaks sessions" as the highest-risk failure scenario.

**Consequences:**
- Development and CI benefit from strict error detection.
- Production sessions are never broken by the hook.
- Errors are logged to stderr, making them visible for diagnosis without cluttering normal output.
