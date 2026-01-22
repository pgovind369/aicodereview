# Testing GitHub Copilot Code Review System

This guide provides comprehensive testing procedures to verify the code review system works correctly.

## Prerequisites

- GitHub Copilot installed and activated
- VS Code, JetBrains IDE, or Eclipse with Copilot plugin
- Git repository initialized
- `.github/agents/` directory in project root

## Quick Verification

### 1. Check Installation

```bash
# Verify directory structure
ls -la .github/agents/

# Should see:
# codereview.agent.md
# security.agent.md
# owasp.agent.md
# bugs.agent.md
# code-quality.agent.md
# performance.agent.md
# README.md
# TESTING.md
```

### 2. Verify YAML Frontmatter

```bash
# Check if agents have proper frontmatter
head -n 10 .github/agents/security.agent.md

# Should show:
# ---
# name: security
# description: ...
# tools: [...]
# model: sonnet
# target: vscode
# ---
```

### 3. Test Agent Availability

Open Copilot chat and type `@` - you should see:
- `@codereview`
- `@security`
- `@owasp`
- `@bugs`
- `@code-quality`
- `@performance`

## Test Scenarios

### Test 1: Security Vulnerabilities

**Objective**: Verify security agent detects SQL injection

**Steps**:

1. Create a test file with SQL injection:
```java
// src/test/SecurityTest.java
package com.example.test;

public class SecurityTest {
    public void vulnerableMethod(String userId) {
        String query = "SELECT * FROM users WHERE id = " + userId;
        // Execute query
    }
}
```

2. Check git status:
```bash
git status  # Should show SecurityTest.java as untracked or modified
```

3. Run code review:
```
@codereview
```

**Expected Result**:
- ✅ Detects CRITICAL SQL Injection
- ✅ Shows file location: `src/test/SecurityTest.java:line`
- ✅ Provides PreparedStatement fix
- ✅ Includes CWE reference

### Test 2: OWASP Issues

**Objective**: Verify OWASP agent maps to correct categories

**Steps**:

1. Create broken access control:
```typescript
// src/api/users.ts
export async function getUser(req: Request, res: Response) {
    const userId = req.params.id;
    const user = await db.users.findById(userId);
    // Missing authorization check!
    return res.json(user);
}
```

2. Run code review:
```
@codereview
```

**Expected Result**:
- ✅ Detects A01:2021 - Broken Access Control
- ✅ Severity: HIGH or CRITICAL
- ✅ Suggests authorization check
- ✅ Links to OWASP documentation

### Test 3: Bug Detection

**Objective**: Verify bugs agent finds null pointer issues

**Steps**:

1. Create null pointer vulnerability:
```python
# src/services/user_service.py
def get_user_email(user_id):
    user = find_user(user_id)
    return user.email.lower()  # user might be None!
```

2. Run code review:
```
@codereview
```

**Expected Result**:
- ✅ Detects potential NoneType error
- ✅ Severity: HIGH
- ✅ Suggests null check or Optional handling
- ✅ Provides test case suggestion

### Test 4: Code Quality

**Objective**: Verify code-quality agent detects complexity

**Steps**:

1. Create overly complex function:
```javascript
// src/utils/validator.js
function validateOrder(order) {
    if (order) {
        if (order.status === 'pending') {
            if (order.items && order.items.length > 0) {
                if (order.customer) {
                    if (order.customer.verified) {
                        if (order.total > 0) {
                            if (order.payment) {
                                return true;
                            }
                        }
                    }
                }
            }
        }
    }
    return false;
}
```

2. Run code review:
```
@codereview
```

**Expected Result**:
- ✅ Detects high cyclomatic complexity
- ✅ Severity: MEDIUM
- ✅ Suggests refactoring with early returns
- ✅ Shows improved version

### Test 5: Performance Issues

**Objective**: Verify performance agent catches N+1 queries

**Steps**:

1. Create N+1 query problem:
```python
# src/views.py
def list_orders(request):
    orders = Order.objects.all()
    for order in orders:
        customer = Customer.objects.get(id=order.customer_id)  # N+1!
        print(customer.name)
```

2. Run code review:
```
@codereview
```

**Expected Result**:
- ✅ Detects N+1 query problem
- ✅ Severity: HIGH
- ✅ Suggests `select_related` or `prefetch_related`
- ✅ Explains performance impact

### Test 6: Multiple Issues

**Objective**: Verify all agents run in parallel and aggregate results

**Steps**:

1. Create file with multiple issue types:
```java
// src/ComplexService.java
package com.example;

import java.util.*;

public class ComplexService {
    // Security issue: hardcoded credentials
    private String apiKey = "sk_live_12345";

    // Bug: potential null pointer
    public String getUserName(Long userId) {
        User user = findUser(userId);
        return user.getName().toUpperCase(); // No null check
    }

    // Performance: O(n²) algorithm
    public boolean hasDuplicate(List<String> items) {
        for (int i = 0; i < items.size(); i++) {
            for (int j = i + 1; j < items.size(); j++) {
                if (items.get(i).equals(items.get(j))) {
                    return true;
                }
            }
        }
        return false;
    }

    // Code quality: method too long, poor naming
    public void process(String a, String b, int c) {
        // ... 100 lines of code ...
    }
}
```

2. Run code review:
```
@codereview
```

**Expected Result**:
- ✅ Report shows multiple categories
- ✅ Security: Hardcoded credentials (CRITICAL)
- ✅ Bugs: Null pointer issue (HIGH)
- ✅ Performance: O(n²) algorithm (MEDIUM)
- ✅ Quality: Poor naming, long method (LOW)
- ✅ Executive summary shows all severity counts
- ✅ Quick fixes section at bottom

### Test 7: No Issues (Clean Code)

**Objective**: Verify system handles clean code gracefully

**Steps**:

1. Create well-written code:
```typescript
// src/services/secure-user.service.ts
import { hash } from 'bcrypt';

export class UserService {
    async createUser(data: CreateUserDto): Promise<User> {
        // Input validation
        if (!data.email || !data.password) {
            throw new ValidationError('Email and password required');
        }

        // Secure password hashing
        const hashedPassword = await hash(data.password, 12);

        // Parameterized query
        const user = await this.db.query(
            'INSERT INTO users (email, password) VALUES ($1, $2)',
            [data.email, hashedPassword]
        );

        return user;
    }
}
```

2. Run code review:
```
@codereview
```

**Expected Result**:
- ✅ Report shows "No critical issues found"
- ✅ May show INFO-level suggestions
- ✅ Positive feedback: "Great job! Clean code."

### Test 8: Large Diff

**Objective**: Verify system handles large changes

**Steps**:

1. Create or modify multiple files (10+)
2. Run code review:
```
@codereview
```

**Expected Result**:
- ✅ System processes all files
- ✅ May warn about large diff
- ✅ Suggests reviewing in batches
- ✅ Provides findings for all files

### Test 9: Edge Cases

**Objective**: Test error handling

#### No Uncommitted Changes
```bash
git add .
git commit -m "test"
```
Run `@codereview`

**Expected**: Message about no changes detected

#### Non-Git Directory
```bash
cd /tmp/test-no-git
```
Run `@codereview`

**Expected**: Message about not being a git repo

#### Only Non-Source Files Changed
```bash
echo "# Test" > README.md
git status
```
Run `@codereview`

**Expected**: Message about no source files changed

### Test 10: Iterative Review

**Objective**: Verify fix validation workflow

**Steps**:

1. Create code with security issue:
```java
String password = "admin123";
```

2. Run `@codereview` - detects hardcoded credential

3. Fix the issue:
```java
String password = System.getenv("DB_PASSWORD");
```

4. Run `@codereview` again

**Expected Result**:
- ✅ Second review shows issue is fixed
- ✅ Confirms improvement
- ✅ May show: "Great! You've fixed the critical issue"

## Performance Testing

### Test 11: Parallel Execution

**Objective**: Verify agents run in parallel (not sequential)

**Steps**:

1. Create file with multiple issue types
2. Run `@codereview` and note start time
3. Check if agents execute simultaneously

**Metrics to Check**:
- Total execution time should be < sum of individual agents
- If sequential: ~90 seconds (5 agents × 18s each)
- If parallel: ~30 seconds (max agent time)

## Integration Testing

### Test 12: VSCode Integration

**Steps**:
1. Open VS Code
2. Open Copilot chat (Cmd/Ctrl + I)
3. Type `@codereview`
4. Verify:
   - ✅ Agent suggestions appear
   - ✅ Report renders in chat
   - ✅ Code blocks are syntax highlighted
   - ✅ File links are clickable (if supported)

### Test 13: JetBrains Integration

**Steps**:
1. Open IntelliJ/PyCharm/WebStorm
2. Open Copilot panel
3. Type `@codereview`
4. Verify similar to VSCode

### Test 14: CLI Integration

**Steps**:
```bash
# If GitHub Copilot CLI installed
gh copilot chat
> @codereview
```

**Expected**: Same functionality as IDE

## Validation Checklist

After running all tests, verify:

- [ ] All 6 agents detected and available
- [ ] Security agent detects vulnerabilities
- [ ] OWASP agent maps to categories
- [ ] Bugs agent finds logic errors
- [ ] Code quality agent detects smells
- [ ] Performance agent catches inefficiencies
- [ ] Reports are well-formatted
- [ ] Severity levels are correct
- [ ] Quick fixes are actionable
- [ ] Error handling works
- [ ] No false negatives on critical issues
- [ ] False positives are minimal
- [ ] Documentation is clear
- [ ] Installation is straightforward

## Troubleshooting Tests

### Agent Not Found

```bash
# Check if files exist
ls .github/agents/*.agent.md

# Check YAML frontmatter
head -n 10 .github/agents/codereview.agent.md

# Reload IDE/extension
```

### No Findings Reported

```bash
# Verify uncommitted changes
git status

# Check file is source code
file <filename>

# Try explicit invocation
@security  # Test individual agent
```

### Incomplete Reports

```bash
# Check for timeouts
# Try smaller diffs
# Check Copilot CLI logs
```

## Continuous Testing

### After Updates

Run this quick smoke test after modifying agents:

```bash
# Create test file
echo '
public class Test {
    String password = "admin123";
}
' > Test.java

# Run review
@codereview

# Should detect hardcoded credential

# Clean up
rm Test.java
```

## Reporting Issues

If tests fail, collect:

1. **Environment**:
   - OS and version
   - IDE and version
   - Copilot extension version

2. **Test Details**:
   - Which test failed
   - Expected vs actual result
   - Error messages

3. **Files**:
   - Test file content
   - Git status output
   - Agent configuration

## Success Criteria

System is production-ready when:

✅ All 13 test scenarios pass
✅ Agents detect 95%+ of intentional vulnerabilities
✅ Reports are clear and actionable
✅ Performance is acceptable (<60s for typical review)
✅ Error handling is graceful
✅ Documentation is complete

## Next Steps

After successful testing:

1. **Deploy to team**: Share with development team
2. **Integrate CI/CD**: Add to pre-commit hooks or CI pipeline
3. **Gather feedback**: Collect real-world usage data
4. **Iterate**: Improve based on false positives/negatives
5. **Expand**: Add more language support or specialized agents

---

**Happy Testing! 🧪**

For questions or issues, refer to README.md or open a project issue.
