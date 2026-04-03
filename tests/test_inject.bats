#!/usr/bin/env bats
# Integration tests for inject-claude-md.sh
# Satisfies: T6 (hook regression integration tests), RT-2

SCRIPT="$BATS_TEST_DIRNAME/../hooks/scripts/inject-claude-md.sh"

setup() {
  # Create isolated temp environment for each test
  TEST_HOME="$(mktemp -d)"
  TEST_PLUGIN_ROOT="$(mktemp -d)"

  # Create the skill file the script expects
  mkdir -p "$TEST_PLUGIN_ROOT/skills/enforce-commandments"
  echo "# Mock skill" > "$TEST_PLUGIN_ROOT/skills/enforce-commandments/SKILL.md"

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

@test "produces no output in normal mode" {
  run bash "$SCRIPT"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
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
