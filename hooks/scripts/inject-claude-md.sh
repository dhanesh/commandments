#!/bin/bash
# Inject enforce-commandments skill reference into global CLAUDE.md
# Runs on SessionStart to ensure the enforcement skill is always active
#
# Exit codes: always 0 (must never break Claude Code sessions)
# Logging: silent by default, set DEBUG=1 for verbose output
#
# Satisfies: T1, U1, U2, U3, S2, S3

set -euo pipefail

# --- Logging (satisfies: U1, U2) ---

log_error() {
  echo "[engineering-commandments] ERROR: $*" >&2
}

log_debug() {
  if [ "${DEBUG:-0}" = "1" ]; then
    echo "[engineering-commandments] $*" >&2
  fi
}

# --- Top-level ERR trap: always exit 0 (satisfies: U3, TN1 resolution) ---
trap 'log_error "Hook failed (exit $?)"; exit 0' ERR

# --- Main logic ---

main() {
  # Validate environment variables (satisfies: S2)
  if [ -z "${HOME:-}" ] || [ ! -d "$HOME" ]; then
    log_error "\$HOME is not set or does not exist"
    return 1
  fi

  if [ -z "${CLAUDE_PLUGIN_ROOT:-}" ] || [ ! -d "$CLAUDE_PLUGIN_ROOT" ]; then
    log_error "\$CLAUDE_PLUGIN_ROOT is not set or does not exist"
    return 1
  fi

  local CLAUDE_MD="$HOME/.claude/CLAUDE.md"
  local SKILL_PATH="$CLAUDE_PLUGIN_ROOT/skills/enforce-commandments/SKILL.md"
  local MARKER="enforce-commandments/SKILL.md"

  # Validate skill file exists (satisfies: S2)
  if [ ! -f "$SKILL_PATH" ]; then
    log_error "Skill file not found: $SKILL_PATH"
    return 1
  fi

  # Create CLAUDE.md if it doesn't exist (satisfies: S3 -- only writes to CLAUDE.md)
  if [ ! -f "$CLAUDE_MD" ]; then
    log_debug "Creating $CLAUDE_MD with enforcement skill reference"
    # Ensure parent directory exists
    mkdir -p "$(dirname "$CLAUDE_MD")"
    printf '%s\n\n%s\n' "# Engineering Standards" "@${SKILL_PATH}" > "$CLAUDE_MD"
    log_debug "Created $CLAUDE_MD"
    return 0
  fi

  # Check if reference already exists (idempotent -- satisfies: RT-1.2 data consistency)
  if grep -q "$MARKER" "$CLAUDE_MD" 2>/dev/null; then
    log_debug "Enforcement skill already referenced in $CLAUDE_MD, skipping"
    return 0
  fi

  # Append the reference
  log_debug "Injecting enforcement skill reference into $CLAUDE_MD"
  cat >> "$CLAUDE_MD" << EOF

# Engineering Commandments - Auto-enforced during development
@${SKILL_PATH}
EOF

  log_debug "Injection complete"
}

main "$@"
