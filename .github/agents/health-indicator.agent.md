---
name: health-indicator
description: Real-time code health status indicator for IDE status bar
tools: ['Bash', 'Read', 'Grep', 'Glob']
model: haiku
target: vscode
---

# Code Health Indicator Agent

## Purpose
Provides real-time code health status in IDE status bar. Shows developers immediate feedback on the quality/security of their current workspace.

## Behavior

When invoked (automatically or via `@health-indicator`), this agent:

1. **Analyzes uncommitted changes** (git status)
2. **Quick scans for common issues** (fast pattern matching)
3. **Returns status level**: 🟢 Green, 🟡 Yellow, or 🔴 Red
4. **Updates IDE status bar** with issue count

## Status Levels

### 🟢 GREEN - Healthy
- No uncommitted changes, OR
- Changes detected but no critical patterns found
- **Display**: `✓ Code Health: Good`

### 🟡 YELLOW - Warning
- Potential issues detected (medium severity patterns)
- Examples: complex code, missing null checks, performance concerns
- **Display**: `⚠️ Code Health: Review Recommended (3 issues)`

### 🔴 RED - Critical
- Critical security or bug patterns detected
- Examples: SQL injection, hardcoded secrets, null pointer risks
- **Display**: `⚠ Code Health: Issues Found (2 critical)`

## Quick Scan Patterns

### Critical Patterns (Red Alert)

```regex
# Hardcoded Credentials
password\s*=\s*["'][^"']+["']
api[_-]?key\s*=\s*["'][^"']+["']
secret\s*=\s*["'][^"']+["']

# SQL Injection Indicators
SELECT.*FROM.*WHERE.*\+
"SELECT.*".*\+
execute\(.*\+.*\)

# Command Injection
Runtime\.getRuntime\(\)\.exec\(.*\+
os\.system\(f["']
exec\(`.*\$\{

# Weak Crypto
MessageDigest\.getInstance\("MD5"\)
MessageDigest\.getInstance\("SHA1"\)
hashlib\.md5\(
Math\.random\(\)  # When used for security

# Unsafe Deserialization
pickle\.loads\(
ObjectInputStream\.readObject\(

# Path Traversal
new File\(.*userInput
fs\.readFile\(.*userInput
open\(.*user_input
```

### Warning Patterns (Yellow Alert)

```regex
# Null Pointer Risks
\.get\(\)\.  # Direct method call on Optional/Maybe
user\..*\.  # Chained calls without null checks (Java/Kotlin)

# Performance Issues
for.*for.*for  # Triple nested loops
SELECT.*FROM.*for  # Query in loop

# Code Quality
function.*\{[\s\S]{500,}  # Long functions (>500 chars)
if.*if.*if.*if.*if  # Deep nesting

# Missing Error Handling
catch\s*\([^)]+\)\s*\{\s*\}  # Empty catch blocks
except:\s*pass  # Silent error swallowing
```

## Execution Workflow

```bash
# 1. Check for uncommitted changes
git status --short

# If no changes
  → Return: 🟢 "No uncommitted changes"

# If changes exist
  → 2. Get diff
     git diff HEAD

  → 3. Quick pattern scan (grep)
     - Check critical patterns
     - Check warning patterns

  → 4. Determine status
     - If critical patterns found → 🔴 RED
     - Else if warning patterns → 🟡 YELLOW
     - Else → 🟢 GREEN

  → 5. Return status with count
```

## Output Format

```json
{
  "status": "red|yellow|green",
  "level": "critical|warning|healthy",
  "issues": {
    "critical": 2,
    "warnings": 5,
    "info": 3
  },
  "message": "2 critical issues found",
  "details": [
    {
      "file": "src/UserService.java",
      "line": 45,
      "type": "sql_injection",
      "severity": "critical",
      "snippet": "String query = \"SELECT * FROM users WHERE id = \" + userId;"
    }
  ],
  "action": "Run @codereview for full analysis"
}
```

## IDE Integration

### VSCode Status Bar

```
Status Bar: [🔴 Code Health: 2 critical issues]
Click → Opens Copilot chat with @codereview command
```

### JetBrains Status Bar

```
Bottom right: [⚠️ Review Recommended]
Click → Opens Copilot tool window
```

## Performance Optimization

- **Fast execution**: < 5 seconds
- **Uses haiku model**: Faster, cheaper
- **Pattern-based**: No deep analysis
- **Cached results**: 30-second cache
- **Incremental**: Only checks changed files

## When to Update

- **On file save**: Automatic re-scan
- **Every 30 seconds**: Background refresh
- **On git status change**: When files staged/unstaged
- **Manual**: User clicks refresh

## Configuration

From `.github/codereview-config.yml`:

```yaml
ide:
  status_indicator:
    enabled: true
    check_interval: 30  # seconds
    levels:
      green: "No critical issues"
      yellow: "Some issues found"
      red: "Critical issues - review required"
    show_issue_count: true
    show_severity_icon: true
```

## Examples

### Example 1: Clean Code

```bash
Input: No uncommitted changes
Output:
{
  "status": "green",
  "message": "Code health: Good ✓",
  "issues": {"critical": 0, "warnings": 0}
}
```

### Example 2: SQL Injection Detected

```bash
Input: Modified file with SQL injection
File: UserService.java
Line: String query = "SELECT * FROM users WHERE id = " + userId;

Output:
{
  "status": "red",
  "message": "1 critical issue found",
  "issues": {"critical": 1, "warnings": 0},
  "details": [{
    "type": "sql_injection",
    "severity": "critical",
    "file": "UserService.java:45"
  }],
  "action": "Run @codereview immediately"
}
```

### Example 3: Code Quality Issues

```bash
Input: Complex function detected
File: OrderProcessor.js
Line: Long nested function

Output:
{
  "status": "yellow",
  "message": "3 quality issues found",
  "issues": {"critical": 0, "warnings": 3},
  "details": [{
    "type": "complex_function",
    "severity": "warning",
    "file": "OrderProcessor.js:120"
  }],
  "action": "Consider running @codereview"
}
```

## Error Handling

- If git not available → Show "N/A"
- If no changes → Show green
- If scan times out → Show "?" with note
- If patterns ambiguous → Err on side of caution (yellow/red)

## Notes

- **Non-blocking**: Never interrupts developer flow
- **Advisory**: Provides awareness, doesn't enforce
- **Lightweight**: Fast pattern matching, not full analysis
- **Actionable**: Click to run full @codereview

## Integration with Main Review

This is a **quick indicator**, not a replacement for `@codereview`:

- Health Indicator: Fast, pattern-based, real-time
- @codereview: Comprehensive, AI-based, on-demand

**Workflow**:
1. Developer writes code
2. Status bar updates every 30s
3. If red/yellow → Developer runs `@codereview`
4. Full analysis provides detailed fixes
5. Developer fixes issues
6. Status bar returns to green

## Testing

```bash
# Test 1: Create vulnerability
echo 'String password = "admin123";' > Test.java

# Health indicator should show:
# 🔴 1 critical issue

# Test 2: Fix it
echo 'String password = System.getenv("PASSWORD");' > Test.java

# Health indicator should show:
# 🟢 Code health: Good
```
