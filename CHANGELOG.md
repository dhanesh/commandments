# Changelog

All notable changes to the engineering-commandments plugin are documented here.
Format follows [Keep a Changelog](https://keepachangelog.com/).

## [1.1.0] - 2026-04-03

### Added
- `set -euo pipefail` with ERR trap wrapper for fail-safe hook execution
- Environment variable validation (`$HOME`, `$CLAUDE_PLUGIN_ROOT`, `$SKILL_PATH`)
- Diagnostic logging: `log_error` (always stderr), `log_debug` (gated by `DEBUG=1`)
- Bats-core integration tests (17 tests covering 4 critical scenarios)
- GitHub Actions CI pipeline (ShellCheck, JSON validation, bats tests)
- Automated release workflow on merge to main
- Makefile for local CI (`make all`, `make test`, `make lint`, `make validate`)
- Architecture Decision Records in `docs/DECISIONS.md`
- CONTRIBUTING.md with development workflow
- This CHANGELOG

### Changed
- Hook script now wraps logic in `main()` function for trap scoping
- Hook script validates all paths before use (security hardening)

## [1.0.0] - 2026-04-02

### Added
- Initial plugin with two skills: `commandments` (assessment) and `enforce-commandments` (always-active)
- SessionStart hook for automatic CLAUDE.md injection
- 10 Engineering Commandments with 5-level maturity criteria
- Three enforcement gates: specification, implementation, review
- Plugin marketplace configuration
