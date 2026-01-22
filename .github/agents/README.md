# GitHub Copilot Code Review System

**Production-Ready** automated code review system for GitHub Copilot that analyzes git changes across security, OWASP vulnerabilities, bugs, code quality, and performance.

## ✨ Features

- **🤖 Automated Git Integration**: Detects modified/new files via `git status`
- **🎯 Diff-Only Analysis**: Reviews only changed code, not entire files
- **⚡ Parallel Agent Execution**: 5 specialized agents run simultaneously
- **🌍 Multi-Language Support**: Java/Kotlin, JavaScript/TypeScript, Python
- **📊 Structured Reports**: Severity-based findings with actionable fixes
- **🔄 No User Input Required**: Fully automated workflow

## 🚀 Quick Start

### Installation

#### VSCode (Recommended)

1. **Prerequisites**:
   - VS Code with GitHub Copilot extension installed
   - GitHub Copilot subscription (Individual, Business, or Enterprise)
   - Git repository

2. **Setup**:
   ```bash
   # Copy the .github/agents/ directory to your project root
   cp -r .github/agents /path/to/your/project/.github/

   # Reload VS Code
   # CMD/CTRL + Shift + P → "Developer: Reload Window"
   ```

#### JetBrains IDEs (IntelliJ, PyCharm, WebStorm)

1. **Prerequisites**:
   - JetBrains IDE with GitHub Copilot plugin
   - GitHub Copilot subscription
   - Git repository

2. **Setup**:
   ```bash
   # Copy agents to project root
   cp -r .github/agents /path/to/your/project/.github/

   # Restart IDE or reload Copilot plugin
   ```

#### Eclipse

1. **Prerequisites**:
   - Eclipse with GitHub Copilot plugin (if available)
   - GitHub Copilot subscription
   - Git repository

2. **Setup**:
   ```bash
   # Copy agents to project root
   cp -r .github/agents /path/to/your/project/.github/

   # Restart Eclipse
   ```

### Basic Usage

1. **Make code changes** (don't commit yet)
2. **Open GitHub Copilot chat**
3. **Type**: `@codereview`
4. **Press Enter** and wait for the comprehensive report

That's it! The system automatically:
- ✅ Detects uncommitted changes
- ✅ Extracts diffs
- ✅ Runs 5 review agents in parallel
- ✅ Generates detailed report with fixes

## 📁 Project Structure

```
.github/
└── agents/
    ├── README.md                # This file
    ├── codereview.agent.md     # Main orchestrator
    ├── security.agent.md       # Security vulnerabilities
    ├── owasp.agent.md          # OWASP Top 10
    ├── bugs.agent.md           # Bug detection
    ├── code-quality.agent.md   # Code quality
    └── performance.agent.md    # Performance optimization
```

## 🔍 Review Agents

### @codereview (Orchestrator)
Coordinates all agents, detects git changes, generates unified reports

### @security
- Authentication/authorization flaws
- Credential exposure
- SQL/Command/XSS injection
- Cryptographic issues
- Insecure deserialization

### @owasp
- OWASP Top 10 2021 mapping
- A01: Broken Access Control
- A02: Cryptographic Failures
- A03: Injection
- A04-A10: Full coverage

### @bugs
- Null/undefined pointer errors
- Race conditions
- Resource leaks
- Off-by-one errors
- Error handling issues
- Async/Promise problems

### @code-quality
- Code smells (God classes, feature envy)
- Cyclomatic complexity
- SOLID principle violations
- Naming conventions
- Code duplication

### @performance
- N+1 query problems
- Inefficient algorithms (O(n²) when O(n) possible)
- Memory leaks
- Blocking operations
- Missing caching

## 📖 Usage Examples

### Basic Review
```
@codereview
```
Reviews all uncommitted changes

### Focused Review
```
@codereview for the authentication changes
```
Provide context for more targeted analysis

### After Fixing Issues
```
@codereview - did I fix the critical issues?
```
Verify your fixes resolved the problems

### Specific File
```
@codereview only UserService.java
```
Review a specific file (if supported by Copilot)

## 📊 Sample Output

```markdown
# 🔍 Code Review Report

**Generated**: 2026-01-22 15:30:00
**Branch**: feature/user-auth
**Files Analyzed**: 3
**Total Issues**: 8

## 📊 Executive Summary
- 🔴 Critical: 1
- 🟠 High: 2
- 🟡 Medium: 3
- 🔵 Low: 2

## 🛡️ Security Issues

### [CRITICAL] SQL Injection Vulnerability
**File**: `src/UserService.java:45`
**Category**: Security
**Agent**: @security

**Issue**: User input directly concatenated into SQL query

**Code**:
```java
String query = "SELECT * FROM users WHERE id = " + userId;
```

**Fix**:
```java
String query = "SELECT * FROM users WHERE id = ?";
PreparedStatement stmt = conn.prepareStatement(query);
stmt.setLong(1, userId);
```

[... more findings ...]
```

## 🎯 Severity Levels

| Severity | Description | Action Required |
|----------|-------------|-----------------|
| 🔴 **Critical** | Security breaches, RCE, data exposure | **Immediate** - Fix before commit |
| 🟠 **High** | Authentication issues, significant bugs | **Urgent** - Fix within hours |
| 🟡 **Medium** | Quality issues, moderate performance | **Important** - Fix within days |
| 🔵 **Low** | Minor improvements, defense-in-depth | **Optional** - Nice to have |
| ℹ️ **Info** | Suggestions, best practices | **FYI** - Consider for future |

## ✅ Best Practices

### When to Run @codereview

**✅ DO run**:
- Before committing changes
- Before creating pull requests
- After implementing new features
- After refactoring code
- When fixing bugs

**❌ DON'T run**:
- On committed code (reviews uncommitted changes)
- After every single line change (batch changes)
- On files you haven't modified

### Interpreting Results

1. **Prioritize by severity**: Fix Critical → High → Medium → Low
2. **Consider context**: Not all suggestions apply to every situation
3. **Learn from findings**: Use reports as learning opportunities
4. **Balance trade-offs**: Some optimizations may reduce clarity
5. **Iterate**: Apply fixes, run @codereview again to verify

### Applying Fixes

**Manual Application**:
```
1. Read the finding
2. Copy the suggested fix
3. Apply to your code
4. Test the change
5. Run @codereview again
```

**Batch Fixing**:
```
1. Review all findings
2. Group similar issues
3. Fix by category (security first)
4. Test incrementally
5. Verify with @codereview
```

## 🧪 Testing the System

### Test 1: Create a Security Vulnerability

```java
// Create a file with SQL injection
public class TestUser {
    public User findUser(String id) {
        String query = "SELECT * FROM users WHERE id = " + id;
        return db.execute(query);
    }
}
```

Run `@codereview` → Should detect **CRITICAL SQL Injection**

### Test 2: Create a Performance Issue

```python
# Create N+1 query problem
users = User.objects.all()
for user in users:
    orders = Order.objects.filter(user_id=user.id)  # N+1!
    print(len(orders))
```

Run `@codereview` → Should detect **HIGH N+1 Query Problem**

### Test 3: Create Code Quality Issue

```javascript
// Create complex nested function
function processOrder(order) {
    if (order) {
        if (order.status === 'pending') {
            if (order.items.length > 0) {
                if (order.customer.verified) {
                    // ... more nesting
                }
            }
        }
    }
}
```

Run `@codereview` → Should detect **MEDIUM Cyclomatic Complexity**

## ⚙️ Configuration

### Customizing Agents

Edit any `.agent.md` file to customize behavior:

```markdown
---
name: security
description: Your custom description
tools: ['Bash', 'Read', 'Grep', 'Glob']  # Available tools
model: sonnet                             # or haiku for speed
target: vscode
---

[Your custom instructions...]
```

### Language-Specific Rules

Add your patterns to agent files:

```markdown
## Custom Project Rules

### Our Framework Patterns
- [ ] Check for XYZ anti-pattern
- [ ] Verify ABC convention
```

### Adjusting Severity

Modify severity guidelines in agent files:

```markdown
## Severity Guidelines
- **CRITICAL**: [your criteria]
- **HIGH**: [your criteria]
```

## 🐛 Troubleshooting

### Issue: "No changes detected"

**Cause**: All changes committed or not in git repo

**Solution**:
```bash
git status  # Verify uncommitted changes
```

### Issue: "Agent not found"

**Cause**: Agents not in correct directory

**Solution**:
```bash
# Verify structure
ls -la .github/agents/
# Should see: codereview.agent.md, security.agent.md, etc.
```

### Issue: "Review is too slow"

**Cause**: Large number of files or very big diffs

**Solution**:
- Review files in batches
- Commit related changes separately
- Focus on critical files first

### Issue: "Too many findings"

**Cause**: Large changes or legacy code

**Solution**:
- Address Critical/High issues first
- Create technical debt backlog for Medium/Low
- Refactor incrementally

### Issue: "False positives"

**Explanation**: Agents are conservative by design

**Solution**:
- Use your judgment to filter
- Customize agent rules for your project
- Provide feedback to improve accuracy

## 🚫 Limitations

- **Git Required**: Must be a git repository with changes
- **Diff-Based**: Only analyzes changed lines, not entire codebase
- **Language Coverage**: Optimized for Java/Kotlin, JS/TS, Python
- **AI-Based**: Accuracy depends on GitHub Copilot's model
- **Static Analysis**: Cannot detect runtime-only issues
- **Token Limits**: Very large diffs may be truncated

## 🔧 Advanced Usage

### CI/CD Integration

While primarily IDE-based, you can integrate into CI:

```yaml
# .github/workflows/code-review.yml
name: Code Review
on: [pull_request]
jobs:
  review:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Run Copilot Review
        run: |
          # Use GitHub Copilot CLI
          gh copilot review
```

### Pre-commit Hook

```bash
#!/bin/sh
# .git/hooks/pre-commit
echo "Running code review..."
gh copilot chat -p "@codereview"
read -p "Issues found. Continue commit? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
fi
```

### Custom Agent Creation

Create your own specialized agent:

```bash
# .github/agents/accessibility.agent.md
---
name: accessibility
description: Review code for WCAG compliance and accessibility issues
tools: ['Read', 'Grep']
model: sonnet
target: vscode
---

[Your accessibility checking instructions...]
```

Then reference in codereview.agent.md:
```yaml
handoffs: ['security', 'owasp', 'bugs', 'code-quality', 'performance', 'accessibility']
```

## 📚 Resources

- [GitHub Copilot Documentation](https://docs.github.com/copilot)
- [Custom Agents Guide](https://docs.github.com/en/copilot/how-tos/use-copilot-agents/coding-agent/create-custom-agents)
- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [CWE Database](https://cwe.mitre.org/)

## 🤝 Contributing

Improve the system:

1. Enhance agent detection patterns
2. Add more language-specific examples
3. Create new specialized agents
4. Share feedback on false positives/negatives
5. Improve documentation

## 📋 Changelog

### v2.0.0 (2026-01-22) - Production Ready
- ✅ Proper `.github/agents/` directory structure
- ✅ YAML frontmatter for all agents
- ✅ Correct `.agent.md` file extensions
- ✅ `@codereview` invocation (not `/codereview`)
- ✅ Parallel agent execution architecture
- ✅ Comprehensive testing instructions
- ✅ Production-ready configuration

### v1.0.0 (2026-01-22) - Initial Release
- ⚠️ Prototype with incorrect directory structure
- ⚠️ Used `.github/copilot/` (wrong path)
- ⚠️ Missing YAML frontmatter

## 📄 License

This code review system is provided as-is for use with GitHub Copilot.

## 💬 Support

- Check Troubleshooting section above
- Review agent documentation in `.github/agents/`
- Consult [GitHub Copilot Documentation](https://docs.github.com/copilot)
- Open issues in your project repository

---

**🚀 Ready to use!** Just type `@codereview` in GitHub Copilot chat and watch it work!

**Remember**: The best code is secure, bug-free, maintainable, and performant. This system helps you achieve all four! 🎯
