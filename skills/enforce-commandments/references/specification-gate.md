# Specification Gate

Use this checklist before finalizing any specification, design, or architecture document.

## Pre-Flight Checklist

### 1. Failure Design
- [ ] Identified failure modes and edge cases
- [ ] Defined fallback behaviors
- [ ] Specified retry/timeout policies
- [ ] Documented degradation paths

### 2. Simplicity Check
- [ ] Chose simplest viable approach
- [ ] Avoided over-engineering
- [ ] Clear data flow (no circular dependencies)
- [ ] Minimal external dependencies

### 3. Test Strategy
- [ ] Unit test approach defined
- [ ] Integration test boundaries identified
- [ ] E2E critical paths listed
- [ ] Test data strategy planned

### 4. Observability Plan
- [ ] Key metrics identified
- [ ] Logging strategy defined
- [ ] Alerting thresholds specified
- [ ] Debug/trace approach documented

### 5. Security Review
- [ ] Authentication/authorization defined
- [ ] Input validation requirements
- [ ] Data classification (PII, sensitive)
- [ ] Threat model considered

### 6. Scale Considerations
- [ ] Expected load documented
- [ ] Bottlenecks identified
- [ ] Caching strategy if needed
- [ ] Async processing where appropriate

## Gate Decision

- **All checked**: Proceed to implementation
- **Missing items**: Address before proceeding
- **Blockers identified**: Escalate for decision
