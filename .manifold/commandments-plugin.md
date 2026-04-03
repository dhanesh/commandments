# commandments-plugin

## Outcome

A Claude Code plugin installable via the plugin system that provides a `/commandments` slash command. When invoked, it:

1. **Identifies the tech stack** of the target repository by analyzing package files, configs, and imports, then researches the stack using WebSearch for context-aware evaluation
2. **Evaluates the codebase** against the 10 Engineering Commandments (from `commandments.md`), assessing maturity at Levels 1-5 for each commandment:
   - Design for Failure
   - Keep It Simple
   - Test Early and Often
   - Build for Observability
   - Document Thy Intent
   - Automate Everything Repeatable
   - Secure by Design
   - Respect Data Consistency
   - Separate Concerns
   - Plan for Scale
3. **Generates/updates a markdown report** (`claudedocs/commandments-report.md`) with:
   - Tech stack summary
   - Per-commandment maturity level assessment with evidence
   - Overall maturity score
   - Actionable improvement steps prioritized by impact
   - History section appended with each run
4. **Researches actionable recommendations** using WebSearch to provide well-informed, stack-specific guidance
5. **Updates the report on each run**, appending assessment history

The plugin should follow the Claude Code plugin structure with proper `plugin.json`, skill definitions, and bundled commandments definition.

---

## Constraints

### Business

#### B1: Evaluate All 10 Commandments

Every run of `/commandments` must assess all 10 Engineering Commandments. No partial evaluations or commandment skipping.

> **Rationale:** The commandments form a holistic engineering quality model. Partial evaluation gives a misleading picture of maturity.

#### B2: Use 5-Level Maturity Model

Each commandment must be assessed using the exact 5-level maturity scale defined in `commandments.md` (Level 1: Initial through Level 5: Optimizing), with the level criteria as defined in the source document.

> **Rationale:** Consistency with the established maturity model ensures assessments are comparable across runs and repos.

#### B3: Stack-Specific Actionables, Not Generic Advice

Recommended improvement actions must reference the actual tech stack, frameworks, and tools found in the repository. Generic advice like "add error handling" is insufficient -- must say HOW for THIS stack.

> **Rationale:** Pre-mortem validated. Generic advice is the #1 reason users stop trusting the report and abandon the tool.

#### B4: Prioritize Actions by Impact

The actionable improvement list must be ordered by estimated impact, considering both the severity of the gap and the effort to close it.

> **Rationale:** Teams have limited capacity. Highest-impact improvements first ensures maximum ROI from the assessment.

### Technical

#### T1: Identify Tech Stack Before Evaluation

The plugin must analyze the repository's package files (package.json, requirements.txt, go.mod, Cargo.toml, pom.xml, etc.), configuration files, and directory structure to identify the tech stack before any commandment evaluation begins.

> **Rationale:** Stack identification grounds the entire evaluation -- error handling patterns differ between Express.js and Spring Boot.

#### T2: WebSearch for Stack-Specific Best Practices

Use WebSearch to research current best practices for the detected tech stack before generating actionable recommendations. Queries should target specific patterns (e.g., "React error boundaries best practices 2026").

> **Rationale:** AI training data becomes stale. WebSearch ensures recommendations reflect the latest framework versions, deprecations, and community standards.

#### T3: Follow Claude Code Plugin Structure

The plugin must use the standard Claude Code plugin structure: `.claude-plugin/plugin.json` manifest, `skills/` directory with `SKILL.md` for the `/commandments` command, and optional `hooks/` and `agents/` directories at root level.

> **Rationale:** Technical reality -- Claude Code auto-discovers plugin components from standard directory locations. Non-standard structure won't be loaded.

#### T4: Deep Analysis with Explore Agents

Codebase evaluation must use Explore agents (or equivalent deep analysis) to scan for patterns like error handling coverage, test presence, logging practices, security patterns, etc. -- not just file existence checks.

> **Rationale:** Surface-level heuristics (e.g., "tests/ directory exists") produce the shallow assessments identified as the top pre-mortem risk.

#### T5: Report Output to claudedocs/

The markdown report must be written to `claudedocs/commandments-report.md`, creating the `claudedocs/` directory if it doesn't exist.

> **Rationale:** Follows the user's file organization rules -- reports and analyses belong in `claudedocs/`, not the project root.

#### T6: Commandments Definition Bundled in Plugin

The 10 commandments with their 5-level maturity definitions must be bundled inside the plugin (not referenced from the target repo).

> **Rationale:** Self-contained plugin works on any repository without requiring the target repo to have a `commandments.md`.

#### T7: Works on Any Repository

The plugin must function on repositories of any language, framework, or structure. Detection and evaluation should gracefully handle unknown or polyglot stacks.

> **Rationale:** A plugin that only works on Node.js repos has limited utility. Must handle Python, Go, Java, Rust, monorepos, etc.

### User Experience

#### U1: Single Command Trigger

Running `/commandments` (with no arguments required) must trigger the full evaluation pipeline: stack detection, research, evaluation, report generation.

> **Rationale:** Minimal friction maximizes adoption. Users shouldn't need to configure or parameterize for standard usage.

#### U2: Evidence-Backed Maturity Levels

Each commandment's maturity level must cite specific evidence from the codebase: file paths, patterns found, metrics, presence/absence of specific practices.

> **Rationale:** Pre-mortem validated. Without evidence, assessments feel arbitrary and users lose trust in the tool.

#### U3: Assessment History in Report

The report must include a history section showing previous assessment dates and overall scores, appended on each run.

> **Rationale:** Tracking progress over time motivates continuous improvement and demonstrates ROI of engineering investments.

#### U4: Self-Explanatory Report

The report must be readable and useful without requiring familiarity with the plugin or the commandments framework. Each section should include enough context.

> **Rationale:** Reports get shared with managers, new team members, and stakeholders who may not have run the tool themselves.

### Security

#### S1: No Sensitive Data in WebSearch Queries

WebSearch queries must only reference technology names, framework versions, and general patterns -- never file contents, variable names, API keys, internal URLs, or proprietary code.

> **Rationale:** WebSearch queries may be logged or visible. Leaking internal codebase details through search queries is a data exfiltration risk.

#### S2: Read-Only Codebase Access

The plugin must only read codebase files for analysis. It must never modify, create, or delete source code files in the target repository. Only `claudedocs/commandments-report.md` should be written.

> **Rationale:** An assessment tool that modifies code violates the principle of least surprise and could introduce bugs.

### Operational

#### O1: Standard Plugin Installation

The plugin must be installable via the standard Claude Code `/plugin install` mechanism or direct directory installation.

> **Rationale:** Technical reality -- non-standard installation creates friction and maintenance burden.

#### O2: No External Dependencies

The plugin must work using only Claude Code's built-in tools (Read, Grep, Glob, Bash, WebSearch, Write, Agent) without requiring external CLIs, services, or API keys.

> **Rationale:** External dependencies create setup friction and failure modes. Claude Code's built-in tools are sufficient for codebase analysis.

#### O3: Report Updates Preserve History

Each run must append to the history section rather than overwriting it, while the main assessment sections show the latest evaluation.

> **Rationale:** Historical data enables trend analysis and demonstrates improvement over time.

---

## Tensions

### TN1: Deep Analysis vs Resource Consumption

Deep analysis with Explore agents (T4) across all 10 commandments (B1) consumes significant tokens and time. Evaluating each commandment thoroughly creates a resource tension between thoroughness and practical usability.

> **Resolution:** Use parallel Explore agents organized by commandment clusters (3-4 agents covering related commandments). This maximizes throughput while keeping analysis deep. Accept higher token cost as the price of trustworthy assessments.
>
> **Propagation:** U2 (evidence-backed levels) is LOOSENED -- parallel analysis yields more evidence per commandment.

### TN2: Any-Repo Support vs Stack-Specific Actionables

Supporting any repository (T7) makes it harder to give truly stack-specific recommendations (B3). Obscure or polyglot stacks may yield poor WebSearch results, triggering the "generic advice" pre-mortem concern.

> **Resolution:** Graceful degradation -- provide stack-specific actionables for recognized technologies, fall back to general best practices for unknown ones. Clearly label which recommendations are stack-specific vs. general fallback. This preserves universality while being transparent about confidence.
>
> **Propagation:** B3 (stack-specific actionables) is TIGHTENED -- unknown stacks receive general advice labeled as fallback. Partial satisfaction acknowledged.

### TN3: WebSearch Research Quality vs Data Privacy

Getting stack-specific recommendations (T2) requires targeted searches, but overly specific queries could include internal details (S1). S1 is INVARIANT and takes precedence.

> **Resolution:** WebSearch queries use only technology names and general pattern names (e.g., "Express.js error handling middleware best practices 2026"). Never include internal file paths, variable names, API endpoints, or proprietary identifiers. Accept broader search results as the cost of privacy.
>
> **Propagation:** T2 (WebSearch research) is TIGHTENED -- queries limited to technology names yield broader but still useful results.

### TN4: Single Command Simplicity vs Deep Analysis Duration

A single `/commandments` command (U1) that runs deep analysis (T4) may feel unresponsive to the user -- long wait with no feedback.

> **Resolution:** The skill SKILL.md includes explicit instructions for the LLM to provide progress updates as it works through each phase (stack detection, research, per-commandment evaluation, report generation). No architectural change needed -- solved via prompting in the skill definition.
>
> **Propagation:** No constraints affected.

---

## Required Truths

### RT-1: Plugin Structure Valid and Discoverable

Claude Code must auto-discover the plugin when installed. Requires `.claude-plugin/plugin.json` with correct schema and `skills/Commandments/SKILL.md` in the expected location.

**Gap:** Plugin does not exist yet. Both files must be created.

- RT-1.1: `.claude-plugin/plugin.json` with correct manifest schema
- RT-1.2: `skills/Commandments/SKILL.md` auto-discovered by Claude Code

### RT-2: Skill Orchestrates Multi-Phase Pipeline

A single SKILL.md must guide the LLM through a sequential pipeline: stack detection -> WebSearch research -> per-commandment evaluation (with parallel agents) -> report generation/update.

**Gap:** No orchestration logic exists. SKILL.md must encode the full pipeline as LLM instructions.

- RT-2.1: SKILL.md prompt guides LLM through sequential phases with progress updates
- RT-2.2: Each phase produces context that feeds into the next (stack info -> research -> evaluation -> report)

### RT-3: Commandments Criteria Are Machine-Evaluable

The 10 commandments x 5 maturity levels = 50 criteria descriptions must be structured enough for an LLM to assess a codebase against them with evidence.

**Gap:** None -- `commandments.md` exists with clear level descriptions. Must be bundled in plugin.

- RT-3.1: 10 commandments x 5 levels with criteria descriptions bundled in plugin [SPECIFICATION_READY]

### RT-4: Stack Detection Works Across Ecosystems

Must recognize package manifests (package.json, requirements.txt, go.mod, Cargo.toml, pom.xml, build.gradle, etc.), config files, and directory patterns for major language ecosystems.

**Gap:** No detection logic exists. Must be encoded in SKILL.md as file-pattern scanning instructions.

- RT-4.1: Recognizes major package manifest formats (Node, Python, Go, Rust, Java, .NET, Ruby, PHP)
- RT-4.2: Gracefully handles unknown/polyglot stacks with fallback messaging

### RT-5: Report Format Supports Current Assessment + History

Report template must have distinct sections: current assessment (overwritten each run) and history log (appended each run).

**Gap:** No report template exists. Must be defined in SKILL.md.

- RT-5.1: Report template with header, tech stack, per-commandment sections, actionables, and history
- RT-5.2: History append logic that reads existing report and preserves previous entries

### RT-6: WebSearch Yields Actionable Stack-Specific Results

Query templates must use only technology names (S1 compliance) while being specific enough to return useful best-practice results for actionable recommendations.

**Gap:** Query template patterns are definable (SPECIFICATION_READY) but integration with per-commandment findings is not yet designed.

- RT-6.1: Query templates use format: "[Technology] [commandment-topic] best practices [year]" [SPECIFICATION_READY]
- RT-6.2: Results inform per-commandment recommendations with stack-specific guidance

### RT-7: Deep Analysis Extracts Evidence Per Commandment (BINDING CONSTRAINT)

Each commandment must have defined evidence patterns that Explore agents search for in the codebase. This is the binding constraint -- assessment quality depends entirely on this.

**Gap:** No evidence patterns defined. Must create per-commandment search patterns that work across language ecosystems.

- RT-7.1: Each commandment has defined evidence patterns (e.g., "Design for Failure" -> error handling, try/catch, circuit breakers, retry logic, fallback patterns)
- RT-7.2: Patterns are language/framework-agnostic with stack-specific variants
- RT-7.3: Agent prompts specific enough to find real evidence, not just file existence

---

## Solution Space

### Option A: Single Monolithic SKILL.md
- Satisfies: RT-1, RT-2, RT-3, RT-4, RT-5, RT-6, RT-7
- Gaps: Prompt may exceed practical size (~15K tokens)
- Complexity: Low structure, high prompt complexity
- Reversibility: TWO_WAY

### Option B: Skill + Bundled Reference Data <- Recommended
- Satisfies: RT-1, RT-2, RT-3, RT-4, RT-5, RT-6, RT-7
- Gaps: None (with implementation)
- Complexity: Medium -- 3 files (plugin.json, SKILL.md, commandments.md)
- Reversibility: TWO_WAY
- Addresses binding constraint: SKILL.md references bundled commandments.md for evidence patterns, instructs LLM to spawn Explore agents dynamically

### Option C: Skill + Per-Commandment Agents
- Satisfies: RT-1, RT-2, RT-3, RT-4, RT-5, RT-6, RT-7
- Gaps: None (with implementation)
- Complexity: High -- 12+ files, inter-agent coordination
- Reversibility: REVERSIBLE_WITH_COST (refactoring 10 agent files back to one skill)

**Selected: Option B** -- Simplest structure that satisfies all required truths. Dynamic agent spawning from SKILL.md provides the same parallelism as Option C without the file overhead. Addresses the binding constraint (RT-7) by encoding evidence patterns directly in the skill's evaluation instructions.
