# Review Gate

Use this lens when reviewing code, specs, or designs.

## The 10 Questions

Ask these for every review:

### 1. Failure
> "What happens when this fails?"

- Is every error path handled?
- Are there silent failures?
- What's the blast radius?

### 2. Simplicity
> "Is there a simpler way?"

- Can any code be removed?
- Is this over-engineered?
- Would a junior understand this?

### 3. Testing
> "What's not tested?"

- Are edge cases covered?
- What could break silently?
- Is the test meaningful or just coverage?

### 4. Observability
> "Can we debug this in production?"

- If this fails at 3am, can we diagnose it?
- Are the logs useful?
- Can we trace a request end-to-end?

### 5. Documentation
> "Will future-me understand WHY?"

- Is the intent clear?
- Are non-obvious decisions explained?
- Can someone new onboard from docs?

### 6. Automation
> "Is this repeatable without manual steps?"

- Can we deploy this automatically?
- Are there manual configuration steps?
- Is the environment reproducible?

### 7. Security
> "What could be exploited?"

- Is input trusted that shouldn't be?
- Are secrets properly managed?
- What's the attack surface?

### 8. Data
> "What if the input is garbage?"

- Is external data validated?
- What happens with malformed input?
- Are transactions properly bounded?

### 9. Concerns
> "Does this do ONE thing?"

- Is this function/class focused?
- Are responsibilities clear?
- Is coupling minimized?

### 10. Scale
> "What happens at 100x load?"

- Where's the bottleneck?
- Is it stateless?
- Are there N+1 queries?

## Review Verdict

- **Approve**: All questions satisfactorily answered
- **Request Changes**: Specific items need addressing
- **Discuss**: Architectural concerns need resolution
