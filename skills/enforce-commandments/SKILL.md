---
name: enforce-commandments
description: >-
  This skill should be ALWAYS ACTIVE during software development. It automatically
  enforces the 10 Engineering Commandments when the user is writing code, planning
  features, creating specifications, designing architecture, or reviewing code.
  Auto-activates on keywords like "implement", "build", "create", "refactor",
  "design", "architecture", "component", "service", "endpoint", or "module".
---

# Engineering Commandments Enforcement

Enforce the 10 Engineering Commandments during all development activities. This skill auto-activates during code writing, planning, specification, and review.

## The 10 Commandments

Ensure ALL outputs comply with:

### 1. Design for Failure
> Systems should expect and gracefully handle failures

- Error boundaries and fallback states
- Retry logic with exponential backoff
- Circuit breakers for external dependencies
- Graceful degradation paths

### 2. Keep It Simple
> Complexity breeds bugs that testing may not catch

- Prefer straightforward solutions over clever ones
- Avoid premature optimization
- Limit nesting depth (max 3 levels)
- One function = one purpose

### 3. Test Early and Often
> Testing is not optional, it's fundamental

- Unit tests for all business logic
- Integration tests for critical paths
- Test plan BEFORE implementation
- No PR without test coverage

### 4. Build for Observability
> You cannot improve what you cannot measure

- Structured logging (not console.log)
- Metrics for key operations
- Tracing for distributed flows
- Health check endpoints

### 5. Document Thy Intent
> Code tells you how, documentation tells you why

- JSDoc/docstrings for public APIs
- README for each module/service
- ADRs for architectural decisions
- Comments explain WHY, not WHAT

### 6. Automate Everything Repeatable
> All changes must be trackable and reversible

- CI/CD for all deployments
- Infrastructure as Code
- Database migrations (never manual DDL)
- Scripted environment setup

### 7. Secure by Design
> Security is not an afterthought

- Input validation at boundaries
- Parameterized queries (no string concatenation)
- Secrets in environment, never code
- Principle of least privilege

### 8. Respect Data Consistency
> Never trust external data

- Validate ALL external inputs
- Schema validation (Zod, JSON Schema)
- Idempotent operations where possible
- Transaction boundaries defined

### 9. Separate Concerns
> Each component should have one clear responsibility

- Clear module boundaries
- Dependency injection
- Interface-based contracts
- No god objects/functions

### 10. Plan for Scale
> Today's solution should work for tomorrow's load

- Stateless services where possible
- Async processing for heavy operations
- Pagination for list endpoints
- Cache strategies defined

## Enforcement Gates

Apply the appropriate gate checklist based on the current activity. Detailed checklists are in `references/`:

- **Specification/Planning** -- Load `references/specification-gate.md` for the full pre-flight checklist (failure design, simplicity, test strategy, observability, security, scale)
- **Implementation** -- Load `references/implementation-gate.md` before marking tasks complete (error handling, complexity, testing, observability, security, data handling, separation of concerns, documentation)
- **Code Review** -- Load `references/review-gate.md` for the 10-question review lens (one per commandment)

## Quick Reference

| # | Commandment | Key Question |
|---|-------------|--------------|
| 1 | Design for Failure | "What happens when this fails?" |
| 2 | Keep It Simple | "Is there a simpler way?" |
| 3 | Test Early | "How will we test this?" |
| 4 | Observability | "Can we debug this in production?" |
| 5 | Document Intent | "Will future-me understand WHY?" |
| 6 | Automate | "Can this be scripted?" |
| 7 | Secure by Design | "What could be exploited?" |
| 8 | Data Consistency | "What if the input is garbage?" |
| 9 | Separate Concerns | "Does this do ONE thing?" |
| 10 | Plan for Scale | "What happens at 100x load?" |
