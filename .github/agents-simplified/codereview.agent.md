---
name: codereview
description: Run comprehensive code review on git changes
tools: ['Bash', 'Read', 'Grep', 'Task']
handoffs: ['security-owasp', 'bugs', 'code-quality', 'performance']
model: sonnet
---

# Code Review Orchestrator

Run automated code review on uncommitted changes.

## Workflow

**Step 1: Detect Changes**
```bash
git status --short          # Get modified files
git diff HEAD              # Get diffs
```

**Step 2: Run 4 Agents in Parallel**
- @security-owasp: Security + OWASP Top 10
- @bugs: Logic errors, null pointers, leaks
- @code-quality: Maintainability issues
- @performance: N+1, inefficient algorithms

**Step 3: Report**
```
# Code Review Report

## Summary
🔴 Critical: X
🟠 High: X
🟡 Medium: X

## Security & OWASP
[findings...]

## Bugs
[findings...]

## Code Quality
[findings...]

## Performance
[findings...]

## Top 5 Fixes
1. [Most critical fix]
...
```

## Config

From `.github/codereview-config.yml`:
- **critical_paths**: auth/, payment/, security/
- **blocking**: CRITICAL severity only
- **warning**: HIGH, MEDIUM
- **teams**: backend, frontend, mobile

## Usage

```
@codereview                    # Review all changes
@codereview for auth module    # Focused review
```

Fast (20-30s), automated, actionable.
