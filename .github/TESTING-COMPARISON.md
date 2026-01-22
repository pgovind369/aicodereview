# Testing Guide: Original vs Simplified Agents

Compare performance and results between the two systems before making a final choice.

---

## 📁 Current Setup

You now have **both** versions installed:

```
.github/
├── agents/                    # Original (6 agents, verbose)
│   ├── codereview.agent.md
│   ├── security.agent.md
│   ├── owasp.agent.md
│   ├── bugs.agent.md
│   ├── code-quality.agent.md
│   ├── performance.agent.md
│   ├── health-indicator.agent.md
│   └── proactive-reminder.agent.md
│
└── agents-simplified/         # Simplified (5 agents, concise)
    ├── codereview.agent.md
    ├── security-owasp.agent.md    # Merged security + OWASP
    ├── bugs.agent.md
    ├── code-quality.agent.md
    ├── performance.agent.md
    └── code-monitor.agent.md      # Merged indicator + reminders
```

---

## 🧪 Testing Strategy

### Phase 1: Side-by-Side Comparison (Day 1)
Test both on the same code changes and compare results.

### Phase 2: Pilot Program (Week 1)
Use simplified version for 5 days, collect feedback.

### Phase 3: Decision (End of Week 1)
Choose which version to keep based on metrics.

---

## 🚀 Quick Test (5 minutes)

### Test 1: Create a Security Vulnerability

```bash
# Create test file with multiple issues
cat > TestSecurity.java << 'EOF'
package com.test;

public class TestSecurity {
    // CRITICAL: Hardcoded credential
    private String apiKey = "sk_live_12345";

    // CRITICAL: SQL Injection
    public User getUser(String userId) {
        String query = "SELECT * FROM users WHERE id = " + userId;
        return db.execute(query);
    }

    // HIGH: Weak crypto
    public String hash(String password) {
        return MessageDigest.getInstance("MD5").digest(password);
    }

    // MEDIUM: Missing null check
    public String getName(User user) {
        return user.getName().toUpperCase();
    }
}
EOF

git add TestSecurity.java
```

### Test Original System

```bash
# In Copilot chat, type:
@codereview

# Or from terminal (if Copilot CLI installed):
gh copilot suggest "@codereview"

# Record:
# - Time taken: _____ seconds
# - Issues found: _____
# - Cost (check API usage): $_____
```

### Test Simplified System

```bash
# Temporarily rename directories to test simplified
mv .github/agents .github/agents-original-backup
mv .github/agents-simplified .github/agents

# In Copilot chat, type:
@codereview

# Record:
# - Time taken: _____ seconds
# - Issues found: _____
# - Cost: $_____

# Restore original
mv .github/agents .github/agents-simplified
mv .github/agents-original-backup .github/agents
```

### Compare Results

| Metric | Original | Simplified | Winner |
|--------|----------|------------|--------|
| **Time** | ___ sec | ___ sec | ? |
| **Issues Found** | ___ | ___ | ? |
| **False Positives** | ___ | ___ | ? |
| **Cost** | $___ | $___ | ? |
| **Report Clarity** | 1-5 | 1-5 | ? |

---

## 📊 Comprehensive Test Suite

### Test 2: Large Diff (Stress Test)

```bash
# Generate large file with multiple issue types
cat > LargeTest.java << 'EOF'
package com.test;

import java.util.*;

public class LargeTest {
    // Hardcoded credentials (CRITICAL)
    private String password = "admin123";
    private String apiKey = "sk_live_xyz";

    // SQL Injection (CRITICAL)
    public List<User> searchUsers(String query) {
        String sql = "SELECT * FROM users WHERE name LIKE '%" + query + "%'";
        return db.query(sql);
    }

    // N+1 Query (HIGH - Performance)
    public void loadOrders() {
        List<User> users = userRepo.findAll();
        for (User user : users) {
            List<Order> orders = orderRepo.findByUserId(user.getId()); // N+1!
            System.out.println(orders.size());
        }
    }

    // Null Pointer (HIGH - Bug)
    public String getUserEmail(Long id) {
        User user = findUser(id);
        return user.getEmail().toLowerCase(); // No null check
    }

    // Resource Leak (HIGH - Bug)
    public String readFile(String path) {
        FileReader reader = new FileReader(path);
        BufferedReader br = new BufferedReader(reader);
        return br.readLine(); // Never closed
    }

    // Complex Code (MEDIUM - Quality)
    public boolean validate(Order order) {
        if (order != null) {
            if (order.getStatus() != null) {
                if (order.getStatus().equals("pending")) {
                    if (order.getItems() != null) {
                        if (order.getItems().size() > 0) {
                            if (order.getTotal() > 0) {
                                return true;
                            }
                        }
                    }
                }
            }
        }
        return false;
    }

    // O(n²) Algorithm (MEDIUM - Performance)
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
}
EOF

git add LargeTest.java
```

**Run both systems and compare**:
- Time to complete
- Number of issues found
- Accuracy (false positives/negatives)
- Cost

---

## 🎯 What to Look For

### Detection Coverage
Both systems should find:
- ✅ 2 hardcoded credentials (CRITICAL)
- ✅ 2 SQL injections (CRITICAL)
- ✅ 1 N+1 query (HIGH)
- ✅ 2 null pointer risks (HIGH)
- ✅ 1 resource leak (HIGH)
- ✅ 1 complexity issue (MEDIUM)
- ✅ 1 O(n²) algorithm (MEDIUM)

**Total: 10 issues**

### Quality Metrics

**Original System**:
- Pros: Very detailed findings, extensive examples
- Cons: Verbose reports, some duplication between security/OWASP

**Simplified System**:
- Pros: Concise findings, no duplication, faster
- Cons: Less context/examples (but should find same issues)

---

## 🔄 Easy Switching

### Switch to Simplified

```bash
# Backup original
mv .github/agents .github/agents-original

# Activate simplified
mv .github/agents-simplified .github/agents

echo "✅ Now using simplified agents"
```

### Switch Back to Original

```bash
# Restore original
mv .github/agents .github/agents-simplified
mv .github/agents-original .github/agents

echo "✅ Now using original agents"
```

### Use Specific Version for Single Review

```bash
# Test simplified without switching
@codereview --agents-dir=.github/agents-simplified

# Or via git hook override
CODEREVIEW_AGENTS_DIR=.github/agents-simplified git push
```

---

## 📈 Metrics Collection

### Create Results Log

```bash
mkdir -p .github/test-results

cat > .github/test-results/comparison.md << 'EOF'
# Agent Comparison Results

## Test 1: Security Vulnerabilities (TestSecurity.java)

| Metric | Original | Simplified |
|--------|----------|------------|
| Time | | |
| Issues Found | | |
| False Positives | | |
| Cost | | |
| Report Quality (1-5) | | |

### Original Findings
```
[Paste findings here]
```

### Simplified Findings
```
[Paste findings here]
```

## Test 2: Large File (LargeTest.java)

| Metric | Original | Simplified |
|--------|----------|------------|
| Time | | |
| Issues Found | | |
| False Positives | | |
| Cost | | |

## Test 3: Real Codebase

| Metric | Original | Simplified |
|--------|----------|------------|
| Time | | |
| Issues Found | | |
| False Positives | | |
| Cost | | |

## Decision

After testing, we choose: [ ] Original [ ] Simplified

Reasoning:
-
-
-

EOF
```

---

## 🧑‍🤝‍🧑 Pilot Program (Recommended)

### Week 1: Internal Pilot

**Team**: 2-3 developers
**Duration**: 5 days
**Goal**: Real-world comparison

#### Setup

```bash
# Pilot team uses simplified
cd /path/to/repo
mv .github/agents .github/agents-original
mv .github/agents-simplified .github/agents

# Rest of team continues with original
# (or vice versa - split the team)
```

#### Daily Check-in

```markdown
Day 1:
- Reviews run: ___
- Time avg: ___
- Issues found: ___
- Blockers: ___

Day 2:
...

Day 5:
- Total reviews: ___
- Avg time: ___
- Total issues: ___
- Satisfaction (1-5): ___
```

#### Feedback Questions

1. **Speed**: Faster/slower than expected?
2. **Accuracy**: Missing any issues? False positives?
3. **Reports**: Clear and actionable?
4. **Cost**: Worth the savings?
5. **Preference**: Original or simplified?

---

## 📊 Success Criteria

Choose **Simplified** if:
- ✅ Finds 95%+ of issues that original finds
- ✅ 30%+ faster
- ✅ 40%+ cost reduction
- ✅ No critical issues missed
- ✅ Team prefers concise reports

Choose **Original** if:
- ✅ Simplified misses critical issues
- ✅ Team prefers verbose examples
- ✅ Extra detail worth the cost
- ✅ More confidence with detailed reports

---

## 🎯 Recommended Testing Timeline

### Day 1 (Today)
- [x] Both systems installed
- [ ] Run Quick Test (5 min)
- [ ] Record initial comparison

### Day 2-3
- [ ] Run comprehensive tests
- [ ] Test on real codebase
- [ ] Collect metrics

### Day 4-5
- [ ] Pilot with 2-3 developers
- [ ] Gather feedback
- [ ] Calculate actual cost savings

### End of Week
- [ ] Make final decision
- [ ] Remove unused version
- [ ] Update documentation

---

## 🚨 Rollback Plan

If simplified version has issues:

```bash
# Instant rollback
mv .github/agents .github/agents-simplified-failed
mv .github/agents-original .github/agents

# Resume with original
git add .github/
git commit -m "Rollback to original agents - [reason]"
git push
```

No downtime, instant switch.

---

## 💡 Tips for Fair Testing

1. **Same Code**: Test both on identical changes
2. **Same Conditions**: Same time of day, same load
3. **Multiple Tests**: Don't judge on single test
4. **Real Code**: Test on actual work, not just examples
5. **Team Input**: Get feedback from multiple developers

---

## 📝 Next Steps

1. **Run Quick Test** (5 minutes)
   ```bash
   # Copy TestSecurity.java code above
   # Run @codereview with both systems
   ```

2. **Record Results**
   ```bash
   vim .github/test-results/comparison.md
   ```

3. **Share This Guide with Pilot Team**
   ```bash
   # Send them this file
   # Ask for honest feedback
   ```

4. **Make Decision in 1 Week**
   - Review metrics
   - Consider team preference
   - Choose winner

---

## ❓ Questions?

- **Can I use both long-term?** Yes, but unnecessary - choose one
- **What if I'm unsure?** Default to simplified (48% savings is significant)
- **Can I mix them?** Yes, use simplified for most, original for critical reviews
- **Rollback cost?** Zero - just move directories

---

**Ready to test?** Start with the Quick Test above! 🚀
