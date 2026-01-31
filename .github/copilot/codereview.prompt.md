# Code Review Orchestrator

## Command
`/reviewcode`

## Description
Comprehensive automated code review that analyzes git changes and runs parallel review agents for security, OWASP vulnerabilities, bugs, code quality, and performance issues. Intended as a pre-merge check before opening or updating a merge request.

## Behavior
This command automatically:
1. Detects new and modified files using `git status` and `git diff`
2. Extracts relevant code diffs (not entire files)
3. Invokes specialized review agents in parallel
4. Aggregates results into a structured report with actionable fixes

## Supported Languages
- Java/Kotlin (Spring, Jakarta EE, Android)
- JavaScript/TypeScript (Node.js, React, Angular, Vue, Next.js)
- Python (Django, Flask, FastAPI)

## Instructions

When the user invokes `/reviewcode`, follow this orchestration workflow:

### Phase 1: Git Change Detection
1. Run `git status --short` to identify modified (M), added (A), renamed (R), and new (??) files
2. For each identified file, capture both unstaged and staged diffs (`git diff <file>` and `git diff --cached <file>`) and merge them for a full pre-merge view
3. For new files, include the entire content since no previous version exists
4. Filter to only include source code files (skip .md, .json, .txt, etc. unless they contain security configs)
4. Create a context object with: filename, diff content, file extension, change type

### Phase 2: Parallel Agent Invocation
Invoke the following agents **in parallel** (if GitHub Copilot supports parallel execution, otherwise sequentially):

1. **Security Agent** (`agents/security-agent.md`)
   - Focus: Authentication/authorization flaws, credential exposure, injection vulnerabilities, cryptographic issues
   - Input: Diffs from all changed files
   - Output: Security findings with severity (Critical/High/Medium/Low)

2. **OWASP Agent** (`agents/owasp-agent.md`)
   - Focus: OWASP Top 10 vulnerabilities (injection, broken auth, sensitive data exposure, XXE, broken access control, security misconfiguration, XSS, insecure deserialization, components with known vulnerabilities, insufficient logging)
   - Input: Diffs from all changed files
   - Output: OWASP findings mapped to specific categories

3. **Bugs Agent** (`agents/bugs-agent.md`)
   - Focus: Logic errors, null pointer issues, off-by-one errors, resource leaks, race conditions, incorrect error handling
   - Input: Diffs from all changed files
   - Output: Bug findings with likelihood and impact

4. **Code Quality Agent** (`agents/code-quality-agent.md`)
   - Focus: Code smells, complexity, maintainability, naming conventions, code duplication, design patterns
   - Input: Diffs from all changed files
   - Output: Quality findings with refactoring suggestions

5. **Performance Agent** (`agents/performance-agent.md`)
   - Focus: N+1 queries, inefficient algorithms, memory leaks, blocking operations, unoptimized loops
   - Input: Diffs from all changed files
   - Output: Performance findings with optimization suggestions

### Phase 3: Report Generation
After all agents complete, aggregate the results into a structured markdown report:

```markdown
# Code Review Report
**Generated**: [timestamp]
**Files Analyzed**: [count]
**Total Issues**: [count]

## Executive Summary
- 🔴 Critical: [count]
- 🟠 High: [count]
- 🟡 Medium: [count]
- 🔵 Low: [count]
- ℹ️ Info: [count]

---

## Security Issues
[Findings from security-agent]

## OWASP Vulnerabilities
[Findings from owasp-agent]

## Bugs
[Findings from bugs-agent]

## Code Quality
[Findings from code-quality-agent]

## Performance Issues
[Findings from performance-agent]

---

## Actionable Quick Fixes
[Aggregated list of code suggestions with diffs that can be applied]

## Recommendations
[High-level recommendations based on patterns across all findings]
```

### Output Format for Each Finding
Each finding should follow this structure:
```markdown
### [Severity] [Title]
**File**: `path/to/file.ext:line_number`
**Category**: [Security/OWASP/Bug/Quality/Performance]
**Agent**: [agent-name]

**Issue**:
[Clear description of the problem]

**Code**:
```[language]
[Relevant code snippet from diff]
```

**Impact**:
[Explanation of why this matters]

**Fix**:
```[language]
[Suggested code fix]
```

**Rationale**:
[Why this fix addresses the issue]
```

### Phase 4: No User Input Required
- All steps are automated
- Report is delivered directly in the chat window
- User can apply suggested fixes by copying code or using IDE quick-fix features (if available)

## Error Handling
- If `git status` shows no changes, respond: "No changed files detected. Ensure you have uncommitted changes to review."
- If git is not initialized, respond: "This is not a git repository. Code review requires git for change detection."
- If an agent fails, continue with other agents and note the failure in the report

## Notes
- Only analyze diffs, not entire files (unless file is newly added)
- Skip binary files, large files (>10k lines), and non-source files
- If a diff is too large, analyze the most critical sections based on language-specific heuristics
- Always provide actionable fixes, not just descriptions of problems
