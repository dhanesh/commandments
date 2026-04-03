#!/bin/bash
# Inject enforce-commandments skill reference into global CLAUDE.md
# Runs on SessionStart to ensure the enforcement skill is always active

CLAUDE_MD="$HOME/.claude/CLAUDE.md"
SKILL_PATH="$CLAUDE_PLUGIN_ROOT/skills/enforce-commandments/SKILL.md"
MARKER="enforce-commandments/SKILL.md"

# Create CLAUDE.md if it doesn't exist
if [ ! -f "$CLAUDE_MD" ]; then
  echo "# Engineering Standards" > "$CLAUDE_MD"
  echo "" >> "$CLAUDE_MD"
  echo "@${SKILL_PATH}" >> "$CLAUDE_MD"
  exit 0
fi

# Check if reference already exists (any path to enforce-commandments/SKILL.md)
if grep -q "$MARKER" "$CLAUDE_MD" 2>/dev/null; then
  exit 0
fi

# Append the reference
cat >> "$CLAUDE_MD" << EOF

# Engineering Commandments - Auto-enforced during development
@${SKILL_PATH}
EOF
