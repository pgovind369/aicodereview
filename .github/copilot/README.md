# GitHub Copilot Code Review System

An automated code review system for GitHub Copilot that analyzes git changes across multiple dimensions: security vulnerabilities, OWASP issues, bugs, code quality, and performance problems.

## Overview

This system provides a comprehensive `/codereview` command that you can invoke in GitHub Copilot chat (VSCode, JetBrains IDEs, or other supported IDEs) to automatically review your code changes.

### Features

- **Automated Git Integration**: Automatically detects modified and new files using `git status`
- **Diff-Only Analysis**: Analyzes only the changed code (diffs), not entire files
- **Parallel Agent Architecture**: Multiple specialized review agents run in parallel
- **Multi-Language Support**: Java/Kotlin, JavaScript/TypeScript, Python
- **Structured Reports**: Detailed findings with severity levels and actionable fixes
- **No User Input Required**: Fully automated workflow

### Review Agents

1. **Security Agent** - Detects authentication flaws, credential exposure, injection vulnerabilities, cryptographic issues
2. **OWASP Agent** - Maps findings to OWASP Top 10 2021 categories
3. **Bugs Agent** - Identifies logic errors, null pointer issues, race conditions, resource leaks
4. **Code Quality Agent** - Finds code smells, complexity issues, naming violations, SOLID principle violations
5. **Performance Agent** - Catches N+1 queries, inefficient algorithms, memory leaks, blocking operations

## Installation

### For VSCode

1. Ensure you have GitHub Copilot extension installed
2. Copy the `.github/copilot/` directory to the root of your project
3. Reload VSCode or restart the Copilot extension

### For JetBrains IDEs (IntelliJ IDEA, PyCharm, WebStorm, etc.)

1. Ensure you have GitHub Copilot plugin installed
2. Copy the `.github/copilot/` directory to the root of your project
3. Restart the IDE or reload the Copilot plugin

### For Eclipse

1. Ensure you have GitHub Copilot plugin installed (if available)
2. Copy the `.github/copilot/` directory to the root of your project
3. Restart Eclipse

## Project Structure

```
.github/
└── copilot/
    ├── README.md                    # This file
    ├── codereview.prompt.md         # Main orchestrator
    └── agents/
        ├── security-agent.md        # Security review agent
        ├── owasp-agent.md          # OWASP Top 10 agent
        ├── bugs-agent.md           # Bug detection agent
        ├── code-quality-agent.md   # Code quality agent
        └── performance-agent.md    # Performance agent
```

## Usage

### Basic Usage

1. Make changes to your code
2. **Do NOT commit yet** (the review analyzes uncommitted changes)
3. Open GitHub Copilot chat in your IDE
4. Type: `/codereview`
5. Press Enter

The system will automatically:
- Detect changed files using `git status`
- Extract diffs for each changed file
- Run all review agents in parallel
- Generate a comprehensive report with findings

### Example Workflow

```bash
# Make some code changes
vim src/main/java/com/example/UserService.java

# Open Copilot chat and run review
# Type in chat: /codereview

# Review the findings
# Apply suggested fixes
# Commit your improved code
git add .
git commit -m "Implement user service with security fixes"
```

### Sample Output

```markdown
# Code Review Report
**Generated**: 2025-01-22 10:30:00
**Files Analyzed**: 5
**Total Issues**: 12

## Executive Summary
- 🔴 Critical: 2
- 🟠 High: 3
- 🟡 Medium: 5
- 🔵 Low: 2
- ℹ️ Info: 0

---

## Security Issues

### [CRITICAL] SQL Injection Vulnerability
**File**: `src/services/UserService.java:45`
**Category**: Security
**CWE**: CWE-89

**Issue**:
User input is directly concatenated into SQL query without parameterization

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

---

## OWASP Vulnerabilities
[... more findings ...]

## Bugs
[... more findings ...]

## Code Quality
[... more findings ...]

## Performance Issues
[... more findings ...]

## Actionable Quick Fixes
1. Replace SQL concatenation with PreparedStatement in UserService.java:45
2. Add null check before user.getEmail() in UserController.java:78
3. Use HashSet instead of ArrayList for membership checks in OrderService.java:92
[... more fixes ...]
```

## Advanced Usage

### Review Specific Files

While the default behavior reviews all changed files, you can guide Copilot to focus on specific files:

```
/codereview for src/services/PaymentService.java
```

### Understanding Severity Levels

- **🔴 Critical**: Immediate security risks, data breach potential, authentication bypass
- **🟠 High**: Significant security/reliability risks requiring prompt attention
- **🟡 Medium**: Important issues that should be addressed soon
- **🔵 Low**: Minor concerns, defense-in-depth improvements
- **ℹ️ Info**: Suggestions for improvement, nice-to-haves

### Applying Fixes

The review provides code snippets for fixes. You can:

1. **Manual Application**: Copy the suggested code and apply it manually
2. **IDE Quick Fixes**: Some IDEs may offer to apply fixes directly (if supported)
3. **Iterative Review**: Apply fixes, then run `/codereview` again to verify

## Configuration

### Customizing Agents

You can modify agent behavior by editing the respective agent files in `.github/copilot/agents/`:

- **Add language-specific checks**: Edit agent files to include checks for additional languages
- **Adjust severity thresholds**: Modify the severity guidelines in each agent
- **Add custom patterns**: Include project-specific anti-patterns to detect

### Excluding Files

To exclude certain files from review, you can mention it in your prompt:

```
/codereview but skip test files
```

Or edit `codereview.prompt.md` to add file type filters.

## Best Practices

### When to Run Code Review

✅ **DO** run code review:
- Before committing changes
- After implementing new features
- Before creating pull requests
- After refactoring code
- When fixing bugs (to ensure no new issues)

❌ **DON'T** run code review:
- On committed code (it reviews git diffs)
- On files you haven't changed
- After every single line change (batch changes for efficiency)

### Interpreting Results

1. **Prioritize Critical/High Issues**: Address security and critical bugs first
2. **Consider Context**: Not all suggestions may apply to your specific situation
3. **Balance Trade-offs**: Some performance optimizations may reduce code clarity
4. **Learn from Findings**: Use the reports as learning opportunities
5. **Iterative Improvement**: You don't need to fix everything at once

### Integration with CI/CD

For automated reviews in CI/CD pipelines, consider:
- Running code review as part of pre-commit hooks
- Including review reports in pull request comments
- Failing builds on Critical severity issues (configure separately)

## Troubleshooting

### Issue: "No changed files detected"

**Cause**: All changes are committed or you're not in a git repository

**Solution**:
- Ensure you have uncommitted changes: `git status`
- Verify you're in a git repository: `git rev-parse --git-dir`

### Issue: "Code review is too slow"

**Cause**: Large number of changed files or very large diffs

**Solution**:
- Review files in batches
- Commit related changes separately
- Focus review on critical files first

### Issue: "Agent findings overlap"

**Explanation**: This is intentional - security and OWASP agents may find similar issues from different perspectives. This provides comprehensive coverage.

### Issue: "Too many false positives"

**Solution**:
- Agents are conservative by design (better safe than sorry)
- Use your judgment to filter findings
- Submit feedback to improve agent accuracy
- Customize agent rules in the respective .md files

## Limitations

- **Git Dependency**: Requires a git repository with changes
- **Diff-Based**: Only analyzes changed lines, not entire codebase
- **Language Support**: Currently optimized for Java/Kotlin, JavaScript/TypeScript, Python
- **AI-Based**: Results depend on GitHub Copilot's AI capabilities
- **Static Analysis**: Cannot detect runtime-only issues

## Extending the System

### Adding New Agents

1. Create a new agent file: `.github/copilot/agents/your-agent.md`
2. Define the agent's purpose, scope, and checks
3. Include examples and output format
4. Add the agent to `codereview.prompt.md` in Phase 2

Example structure:
```markdown
# Your Agent Name

## Purpose
[What this agent detects]

## Scope
[What it analyzes]

## Review Checklist
[List of checks]

## Output Format
[How findings are reported]
```

### Adding Language Support

Edit each agent file to include:
- Language-specific patterns
- Framework-specific checks
- Common pitfalls for that language

## FAQ

**Q: Can I use this without GitHub Copilot?**
A: These prompts are designed for GitHub Copilot. For standalone use, you'd need to adapt them.

**Q: Does this replace manual code review?**
A: No, it supplements manual review by catching common issues automatically.

**Q: Can I run this on the entire codebase?**
A: It's designed for diffs. For full codebase analysis, use dedicated static analysis tools.

**Q: How accurate are the findings?**
A: Accuracy depends on GitHub Copilot's AI. Most findings are valid, but use your judgment.

**Q: Can I integrate this with GitHub Actions?**
A: Currently, this is IDE-based. For CI/CD, consider GitHub Code Scanning or similar tools.

**Q: Does this work with other version control systems?**
A: Currently optimized for git. Adapting to other VCS would require modifying the git commands.

## Contributing

To improve the code review system:

1. Enhance agent detection patterns
2. Add more language-specific examples
3. Improve output format and clarity
4. Share false positive/negative findings for refinement
5. Create additional specialized agents

## Version History

- **v1.0.0** (2025-01-22): Initial release with 5 core agents
  - Security Agent
  - OWASP Agent
  - Bugs Agent
  - Code Quality Agent
  - Performance Agent

## License

This code review system is provided as-is for use with GitHub Copilot.

## Support

For issues, questions, or suggestions:
- Check the Troubleshooting section above
- Review agent documentation in `.github/copilot/agents/`
- Consult GitHub Copilot documentation
- Open an issue in your project repository

---

**Happy Coding! 🚀**

Remember: The best code is secure, bug-free, maintainable, and performant. This system helps you achieve all four!
