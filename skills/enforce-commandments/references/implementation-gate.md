# Implementation Gate

Use this checklist before marking any implementation task complete.

## Code Quality Checklist

### 1. Error Handling
- [ ] All error paths handled
- [ ] Meaningful error messages
- [ ] No silent failures
- [ ] Cleanup on failure (resources, state)

### 2. Complexity
- [ ] Functions < 50 lines
- [ ] Cyclomatic complexity < 10
- [ ] Nesting depth <= 3
- [ ] Clear naming (no abbreviations)

### 3. Testing
- [ ] Unit tests written
- [ ] Edge cases covered
- [ ] Tests pass locally
- [ ] Coverage meets threshold

### 4. Observability
- [ ] Structured logging added
- [ ] Key operations logged
- [ ] No sensitive data in logs
- [ ] Metrics for SLIs if applicable

### 5. Security
- [ ] Input validated
- [ ] No hardcoded secrets
- [ ] SQL/injection safe
- [ ] Auth checks in place

### 6. Data Handling
- [ ] External data validated
- [ ] Schema enforced
- [ ] Transactions where needed
- [ ] Idempotency considered

### 7. Separation of Concerns
- [ ] Single responsibility per function/class
- [ ] Dependencies injected
- [ ] No god objects
- [ ] Clear interfaces

### 8. Documentation
- [ ] Public APIs documented
- [ ] Complex logic commented (WHY)
- [ ] README updated if needed
- [ ] Types/interfaces documented

## Gate Decision

- **All checked**: Ready for review
- **Missing items**: Complete before PR
- **Technical debt**: Log and track
