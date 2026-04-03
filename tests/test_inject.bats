#!/usr/bin/env bats
# Integration tests for inject-claude-md.sh
# Satisfies: T6 (hook regression integration tests), RT-2

SCRIPT="$BATS_TEST_DIRNAME/../hooks/scripts/inject-claude-md.sh"

setup() {
  # Create isolated temp environment for each test
  TEST_HOME="$(mktemp -d)"
  TEST_PLUGIN_ROOT="$(mktemp -d)"

  # Create a mock skill file with expected markers
  mkdir -p "$TEST_PLUGIN_ROOT/skills/enforce-commandments"
  cat > "$TEST_PLUGIN_ROOT/skills/enforce-commandments/SKILL.md" << 'SKILL'
---
name: enforce-commandments
description: Mock skill for testing
---
# Engineering Commandments Enforcement
### 1. Design for Failure
### 2. Keep It Simple
### 3. Test Early and Often
### 4. Build for Observability
### 5. Document Thy Intent
### 6. Automate Everything Repeatable
### 7. Secure by Design
### 8. Respect Data Consistency
### 9. Separate Concerns
### 10. Plan for Scale
SKILL

  export HOME="$TEST_HOME"
  export CLAUDE_PLUGIN_ROOT="$TEST_PLUGIN_ROOT"
}

teardown() {
  rm -rf "$TEST_HOME" "$TEST_PLUGIN_ROOT"
}

# --- Scenario 1: Fresh injection into new CLAUDE.md (RT-2.2) ---

@test "creates CLAUDE.md when it does not exist" {
  run bash "$SCRIPT"
  [ "$status" -eq 0 ]
  [ -f "$HOME/.claude/CLAUDE.md" ]
}

@test "fresh CLAUDE.md contains skill reference" {
  run bash "$SCRIPT"
  [ "$status" -eq 0 ]
  grep -q "enforce-commandments/SKILL.md" "$HOME/.claude/CLAUDE.md"
}

@test "fresh CLAUDE.md contains header" {
  run bash "$SCRIPT"
  [ "$status" -eq 0 ]
  grep -q "# Engineering Standards" "$HOME/.claude/CLAUDE.md"
}

# --- Scenario 2: Idempotent re-injection (RT-2.2) ---

@test "does not duplicate reference on second run" {
  bash "$SCRIPT"
  bash "$SCRIPT"
  local count
  count=$(grep -c "enforce-commandments/SKILL.md" "$HOME/.claude/CLAUDE.md")
  [ "$count" -eq 1 ]
}

@test "second run exits 0" {
  bash "$SCRIPT"
  run bash "$SCRIPT"
  [ "$status" -eq 0 ]
}

# --- Scenario 3: Missing/unset environment variables (RT-2.2) ---

@test "exits 0 when HOME is unset" {
  unset HOME
  run bash "$SCRIPT"
  [ "$status" -eq 0 ]
}

@test "logs error when HOME is unset" {
  unset HOME
  run bash "$SCRIPT"
  [[ "$output" == *"ERROR"* ]]
}

@test "exits 0 when CLAUDE_PLUGIN_ROOT is unset" {
  unset CLAUDE_PLUGIN_ROOT
  run bash "$SCRIPT"
  [ "$status" -eq 0 ]
}

@test "exits 0 when CLAUDE_PLUGIN_ROOT points to nonexistent dir" {
  export CLAUDE_PLUGIN_ROOT="/nonexistent/path"
  run bash "$SCRIPT"
  [ "$status" -eq 0 ]
}

@test "exits 0 when skill file is missing" {
  rm "$CLAUDE_PLUGIN_ROOT/skills/enforce-commandments/SKILL.md"
  run bash "$SCRIPT"
  [ "$status" -eq 0 ]
  [[ "$output" == *"ERROR"* ]]
}

# --- Scenario 4: No corruption of existing CLAUDE.md content (RT-2.2) ---

@test "preserves existing CLAUDE.md content when injecting" {
  mkdir -p "$HOME/.claude"
  printf '%s\n' "# My Config" "" "Some existing content" > "$HOME/.claude/CLAUDE.md"
  bash "$SCRIPT"
  grep -q "# My Config" "$HOME/.claude/CLAUDE.md"
  grep -q "Some existing content" "$HOME/.claude/CLAUDE.md"
  grep -q "enforce-commandments/SKILL.md" "$HOME/.claude/CLAUDE.md"
}

@test "does not modify CLAUDE.md if reference already present" {
  mkdir -p "$HOME/.claude"
  printf '%s\n' "# My Config" "@path/to/enforce-commandments/SKILL.md" > "$HOME/.claude/CLAUDE.md"
  local before after
  before=$(cat "$HOME/.claude/CLAUDE.md")
  bash "$SCRIPT"
  after=$(cat "$HOME/.claude/CLAUDE.md")
  [ "$before" = "$after" ]
}

# --- JSON config validation (RT-2.3) ---

@test "plugin.json is valid JSON" {
  run python3 -c "import json; json.load(open('$BATS_TEST_DIRNAME/../.claude-plugin/plugin.json'))"
  [ "$status" -eq 0 ]
}

@test "hooks.json is valid JSON" {
  run python3 -c "import json; json.load(open('$BATS_TEST_DIRNAME/../hooks/hooks.json'))"
  [ "$status" -eq 0 ]
}

@test "marketplace.json is valid JSON" {
  run python3 -c "import json; json.load(open('$BATS_TEST_DIRNAME/../.claude-plugin/marketplace.json'))"
  [ "$status" -eq 0 ]
}

# --- Debug mode (U1, U2) ---

@test "emits load confirmation in normal mode" {
  run bash "$SCRIPT"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Engineering Commandments enforcement active"* ]]
}

@test "load confirmation includes commandment count" {
  run bash "$SCRIPT"
  [ "$status" -eq 0 ]
  [[ "$output" == *"10 commandments loaded"* ]]
}

@test "no load confirmation when skill content is invalid" {
  # Replace skill with empty file
  echo "" > "$CLAUDE_PLUGIN_ROOT/skills/enforce-commandments/SKILL.md"
  run bash "$SCRIPT"
  [ "$status" -eq 0 ]
  # Should NOT emit the confirmation (skill missing expected content)
  [[ "$output" != *"enforcement active"* ]]
}

@test "produces debug output when DEBUG=1" {
  export DEBUG=1
  run bash "$SCRIPT"
  [ "$status" -eq 0 ]
  [[ "$output" == *"[engineering-commandments]"* ]]
}

# --- Performance: Hook execution time (T2) ---

@test "hook completes within 5 seconds" {
  local start end elapsed
  start=$(date +%s)
  bash "$SCRIPT"
  end=$(date +%s)
  elapsed=$(( end - start ))
  [ "$elapsed" -lt 5 ]
}

# --- Maturity baseline: Key artifacts exist (B2) ---

# --- Enforcement chain: hooks.json → script → CLAUDE.md → SKILL.md ---

@test "hooks.json wires SessionStart to inject script" {
  local hooks="$BATS_TEST_DIRNAME/../hooks/hooks.json"
  # Verify SessionStart event exists
  run python3 -c "
import json, sys
h = json.load(open('$hooks'))
assert 'hooks' in h, 'missing hooks key'
assert 'SessionStart' in h['hooks'], 'missing SessionStart event'
events = h['hooks']['SessionStart']
assert len(events) > 0, 'no SessionStart handlers'
# Find command referencing our script
found = False
for entry in events:
    for hook in entry.get('hooks', []):
        if 'inject-claude-md.sh' in hook.get('command', ''):
            found = True
assert found, 'inject-claude-md.sh not wired in SessionStart'
"
  [ "$status" -eq 0 ]
}

@test "hooks.json script path resolves to existing file" {
  local repo_root="$BATS_TEST_DIRNAME/.."
  [ -x "$repo_root/hooks/scripts/inject-claude-md.sh" ]
}

@test "SKILL.md exists and has valid YAML frontmatter" {
  local skill="$BATS_TEST_DIRNAME/../skills/enforce-commandments/SKILL.md"
  [ -f "$skill" ]
  # Check frontmatter delimiters
  head -1 "$skill" | grep -q "^---$"
  # Check required frontmatter fields
  grep -q "^name:" "$skill"
  grep -q "^description:" "$skill"
}

@test "SKILL.md contains all 10 commandments" {
  local skill="$BATS_TEST_DIRNAME/../skills/enforce-commandments/SKILL.md"
  grep -q "Design for Failure" "$skill"
  grep -q "Keep It Simple" "$skill"
  grep -q "Test Early" "$skill"
  grep -q "Observability" "$skill"
  grep -q "Document Thy Intent" "$skill"
  grep -q "Automate Everything" "$skill"
  grep -q "Secure by Design" "$skill"
  grep -q "Data Consistency" "$skill"
  grep -q "Separate Concerns" "$skill"
  grep -q "Plan for Scale" "$skill"
}

@test "SKILL.md references all three enforcement gates" {
  local skill="$BATS_TEST_DIRNAME/../skills/enforce-commandments/SKILL.md"
  grep -q "Specification" "$skill"
  grep -q "Implementation" "$skill"
  grep -q "Review" "$skill"
}

@test "end-to-end: hook produces CLAUDE.md with valid skill reference" {
  # Use real plugin root so the skill file has actual content
  local real_root="$BATS_TEST_DIRNAME/.."
  export CLAUDE_PLUGIN_ROOT="$real_root"

  # Run the hook script (simulates SessionStart)
  bash "$SCRIPT"

  # Verify CLAUDE.md was created
  [ -f "$HOME/.claude/CLAUDE.md" ]

  # Extract the @-reference path from CLAUDE.md
  local ref_path
  ref_path=$(grep "^@" "$HOME/.claude/CLAUDE.md" | head -1 | sed 's/^@//')

  # Verify the referenced skill file actually exists
  [ -f "$ref_path" ]

  # Verify it contains the enforcement content
  grep -q "Engineering Commandments" "$ref_path"
}

# --- Maturity baseline: Key artifacts exist (B2) ---

@test "maturity artifacts present: tests, CI, docs" {
  local repo_root="$BATS_TEST_DIRNAME/.."
  [ -f "$repo_root/tests/test_inject.bats" ]
  [ -f "$repo_root/.github/workflows/ci.yml" ]
  [ -f "$repo_root/.github/workflows/release.yml" ]
  [ -f "$repo_root/docs/DECISIONS.md" ]
  [ -f "$repo_root/CHANGELOG.md" ]
  [ -f "$repo_root/CONTRIBUTING.md" ]
  [ -f "$repo_root/Makefile" ]
}
