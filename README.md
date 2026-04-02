# Engineering Commandments Plugin

A Claude Code plugin that evaluates any codebase against 10 Engineering Commandments using a 5-level maturity model. Generates evidence-backed assessment reports with stack-specific, prioritized actionable improvements.

## Installation

```bash
# From the plugin directory
/plugin install /path/to/engineering-commandments

# Or test locally without installing
cc --plugin-dir /path/to/engineering-commandments
```

After installation, run `/reload-plugins` to activate.

## Usage

```
/commandments
```

Run in any repository. No configuration required.

### Flags

- `--quick` -- Skip WebSearch research phase, use only codebase analysis
- `--focus=NAME` -- Deep-dive into a single commandment (e.g., `--focus=security`)

## What It Does

1. **Detects the tech stack** by scanning package manifests, configs, and directory structure
2. **Researches best practices** via WebSearch for the detected stack
3. **Evaluates each commandment** with deep codebase analysis using Explore agents, citing specific file paths and patterns as evidence
4. **Generates a report** at `claudedocs/commandments-report.md` with:
   - Tech stack summary
   - Per-commandment maturity level (1-5) with evidence
   - Overall maturity score
   - Prioritized actionable improvements with stack-specific guidance
   - Assessment history (appended on each run)

## The 10 Commandments

| # | Commandment | Key Question |
|---|-------------|-------------|
| 1 | Design for Failure | What happens when this fails? |
| 2 | Keep It Simple | Is there a simpler way? |
| 3 | Test Early and Often | How will we test this? |
| 4 | Build for Observability | Can we debug this in production? |
| 5 | Document Thy Intent | Will future-me understand WHY? |
| 6 | Automate Everything Repeatable | Can this be scripted? |
| 7 | Secure by Design | What could be exploited? |
| 8 | Secure Data Consistency | What if the input is garbage? |
| 9 | Separate Concerns | Does this do ONE thing? |
| 10 | Plan for Scale | What happens at 100x load? |

Each commandment is assessed using a 5-level maturity scale (Initial through Optimizing). See `commandments.md` for the full criteria.

## Output

Reports are written to `claudedocs/commandments-report.md`. The plugin:
- Creates the `claudedocs/` directory if it doesn't exist
- Updates the report in place on each run
- Appends assessment history so you can track progress over time

## Plugin Structure

```
engineering-commandments/
  .claude-plugin/
    plugin.json              # Plugin manifest
  skills/
    Commandments/
      SKILL.md               # /commandments skill (evaluation pipeline)
  commandments.md            # Bundled maturity criteria (10 x 5 levels)
  README.md                  # This file
```

## Requirements

- Claude Code with plugin support
- No external dependencies -- uses only built-in Claude Code tools (Read, Grep, Glob, Bash, WebSearch, Agent)

## License

MIT
