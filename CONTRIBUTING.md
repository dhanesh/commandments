# Contributing

## Development Setup

1. Clone with submodules:
   ```bash
   git clone --recurse-submodules <repo-url>
   ```

2. Test locally with Claude Code:
   ```bash
   cc --plugin-dir /path/to/engineering-commandments
   ```

3. Run the full quality suite:
   ```bash
   make all
   ```

## Quality Gates

All changes must pass before merge:

- **ShellCheck** -- Zero warnings on all bash scripts (`make lint`)
- **JSON validation** -- All config files parse correctly (`make validate`)
- **Bats tests** -- All integration tests pass (`make test`)

## Making Changes

### Hook Script (`hooks/scripts/inject-claude-md.sh`)

The script uses `set -euo pipefail` with an ERR trap. Key rules:

- **Always exit 0** -- The script must never break Claude Code sessions. The ERR trap ensures this.
- **Validate inputs** -- Check environment variables before use.
- **Log errors to stderr** -- Use `log_error` for error conditions.
- **Use `log_debug`** -- For diagnostic output gated by `DEBUG=1`.
- **Write tests** -- Every behavior change needs a corresponding bats test.

### Skills (`skills/`)

- Keep skills under 2,000 tokens for best performance.
- Use YAML frontmatter with `name`, `description`, and `allowed-tools`.
- Reference materials go in `references/` subdirectories.

### Commit Messages

Use [Conventional Commits](https://www.conventionalcommits.org/):

- `feat:` -- New feature (triggers minor version bump)
- `fix:` -- Bug fix (triggers patch version bump)
- `chore:` -- Maintenance (no version bump)
- `docs:` -- Documentation changes

## Running Tests

```bash
# All tests
make test

# Or directly
./tests/bats/bin/bats tests/

# With debug output for the hook
DEBUG=1 ./tests/bats/bin/bats tests/test_inject.bats
```
