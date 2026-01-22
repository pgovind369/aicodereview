# Shift-Left Development Guide
## Catch Issues Earlier in the Development Lifecycle

This guide explains how to use the GitHub Copilot Code Review system for shift-left development - catching security, quality, and performance issues **before they reach production**.

## 📋 Table of Contents

1. [What is Shift-Left?](#what-is-shift-left)
2. [Architecture Overview](#architecture-overview)
3. [Quick Start](#quick-start)
4. [Configuration](#configuration)
5. [Git Hooks](#git-hooks)
6. [IDE Integration](#ide-integration)
7. [Team Governance](#team-governance)
8. [Metrics & Dashboards](#metrics--dashboards)
9. [Best Practices](#best-practices)
10. [Troubleshooting](#troubleshooting)

---

## What is Shift-Left?

**Shift-left** means moving quality, security, and testing activities **earlier** in the software development lifecycle (SDLC).

### Traditional Approach (Shift-Right)
```
Write Code → Commit → Push → PR Review → QA Testing → Production
                                  ↑                 ↑
                            Issues found here   Issues found here
                            (Expensive to fix)  (Very expensive)
```

### Shift-Left Approach
```
Write Code → [Review] → Commit → [Review] → Push → PR Review → Production
         ↑                  ↑              ↑
   Issues found here   Issues found here  Final check
   (Cheap to fix)      (Still cheap)      (Safety net)
```

### Benefits

| Benefit | Description | Impact |
|---------|-------------|--------|
| **Earlier Detection** | Find issues while context is fresh | 10x faster fixes |
| **Lower Cost** | Fix before code review / QA | 100x cheaper |
| **Better Quality** | Proactive vs reactive | Fewer production bugs |
| **Faster Velocity** | Less rework, faster PRs | 2-3x speedup |
| **Developer Growth** | Learn from immediate feedback | Skill improvement |

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                   SHIFT-LEFT CODE REVIEW SYSTEM                  │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  Layer 1: REAL-TIME (As you type)                              │
│  ┌──────────────────────────────────────┐                       │
│  │  IDE Status Bar Indicator            │                       │
│  │  @health-indicator                   │                       │
│  │  ⚫ Green / 🟡 Yellow / 🔴 Red       │                       │
│  └──────────────────────────────────────┘                       │
│                    ↓ (30s refresh)                              │
│                                                                  │
│  Layer 2: ON-DEMAND (Developer-triggered)                       │
│  ┌──────────────────────────────────────┐                       │
│  │  GitHub Copilot Chat                 │                       │
│  │  @codereview                         │                       │
│  │  → Full analysis of changes          │                       │
│  └──────────────────────────────────────┘                       │
│                    ↓ (on request)                               │
│                                                                  │
│  Layer 3: PROACTIVE (Smart reminders)                           │
│  ┌──────────────────────────────────────┐                       │
│  │  Proactive Reminder Agent            │                       │
│  │  @proactive-reminder                 │                       │
│  │  → Large changes detected            │                       │
│  │  → Critical path modified            │                       │
│  │  → 5 commits without review          │                       │
│  └──────────────────────────────────────┘                       │
│                    ↓ (trigger-based)                            │
│                                                                  │
│  Layer 4: AUTOMATED (Git hooks)                                 │
│  ┌──────────────────────────────────────┐                       │
│  │  Pre-Push Hook                       │                       │
│  │  Automatic @codereview before push   │                       │
│  │  → Blocks if CRITICAL issues         │                       │
│  │  → Warns on HIGH issues              │                       │
│  └──────────────────────────────────────┘                       │
│                    ↓ (enforced)                                 │
│                                                                  │
│  Layer 5: GOVERNANCE (Team rules)                               │
│  ┌──────────────────────────────────────┐                       │
│  │  Configuration & Rules               │                       │
│  │  .github/codereview-config.yml       │                       │
│  │  → Critical paths (auth/, payment/)  │                       │
│  │  → Team-specific rules               │                       │
│  │  → Severity thresholds               │                       │
│  └──────────────────────────────────────┘                       │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## Quick Start

### 1. Install Git Hooks (One-time setup)

```bash
# From repository root
./.github/install-hooks.sh

# Choose option:
# 1 = Symbolic links (recommended)
# 2 = Copy files
# 3 = Configure hooks path
```

###  2. Configure for Your Team

```bash
# Edit configuration
vim .github/codereview-config.yml

# Key settings:
# - enforcement_mode: hybrid (block critical, warn others)
# - critical_paths: Add your security-sensitive code paths
# - team rules: Customize per team (backend, frontend, mobile)
```

### 3. Test the System

```bash
# Create a test vulnerability
echo 'String password = "admin123";' > TestVulnerability.java
git add TestVulnerability.java
git commit -m "test"
git push

# Expected: Push blocked with CRITICAL issue detected
```

### 4. Start Development

```
# Open IDE → GitHub Copilot chat
# Type: @codereview

# Or let hooks do it automatically before push
```

---

## Configuration

### Global Settings

```yaml
# .github/codereview-config.yml

global:
  enforcement_mode: hybrid  # strict | advisory | hybrid | educational

  auto_review:
    on_commit_attempt: false  # Review before commit
    on_push_attempt: true     # Review before push (recommended)
    on_large_changes: true    # Auto-review if >500 lines

  thresholds:
    lines_changed_warning: 500
    files_changed_warning: 10
    complexity_warning: 15
```

### Severity Configuration

```yaml
severity:
  # What blocks commits/pushes
  blocking:
    - CRITICAL

  # What shows warnings
  warning:
    - HIGH
    - MEDIUM

  # What's informational
  informational:
    - LOW
    - INFO

  # Custom overrides
  overrides:
    sql_injection: CRITICAL
    hardcoded_credentials: CRITICAL
    code_complexity: MEDIUM
```

### Critical Paths (Required Review)

```yaml
critical_paths:
  - pattern: "**/auth/**"
    description: "Authentication & Authorization"
    required_agents: [security, owasp]
    block_without_review: true

  - pattern: "**/payment/**"
    description: "Payment Processing"
    required_agents: [security, owasp, bugs]
    block_without_review: true

  - pattern: "**/security/**"
    description: "Security Module"
    required_agents: [security, owasp]
    block_without_review: true
```

### Team-Specific Rules

```yaml
teams:
  backend:
    patterns: ["src/main/java/**", "src/main/kotlin/**"]
    rules:
      - enforce_spring_security: true
      - check_sql_injection: true
      - performance_priority: high
    severity_overrides:
      n_plus_one_query: HIGH

  frontend:
    patterns: ["src/components/**", "**/*.tsx"]
    rules:
      - check_xss: true
      - check_prototype_pollution: true
    severity_overrides:
      xss_vulnerability: CRITICAL
```

---

## Git Hooks

### Pre-Push Hook (Recommended)

**Purpose**: Catch all issues before pushing to remote

**Behavior**:
1. Detects all commits being pushed
2. Extracts diff from remote to local
3. Runs @codereview on changes
4. Blocks push if CRITICAL issues found
5. Warns on HIGH/MEDIUM issues

**Configuration**:

```yaml
git_hooks:
  pre_push:
    enabled: true
    auto_run: true
    block_on_critical: true
    allow_bypass: false  # Prevent --no-verify
    timeout: 60
```

**Testing**:

```bash
# 1. Make changes with vulnerabilities
echo 'String pwd = "admin";' > Auth.java

# 2. Commit
git add Auth.java
git commit -m "add auth"

# 3. Try to push
git push

# Expected: Blocked with security issue
```

### Pre-Commit Hook (Optional)

**Purpose**: Catch issues even earlier, before commit

**Note**: Can slow down commits. Pre-push is usually better.

```yaml
git_hooks:
  pre_commit:
    enabled: false  # Usually disabled
    auto_run: false
    block_on_critical: true
```

### Commit Message Hook

**Purpose**: Enforce commit message standards

```yaml
git_hooks:
  commit_msg:
    enabled: true
    require_ticket: true
    ticket_pattern: "^(feat|fix|refactor|docs|test|chore)\\([A-Z]+-[0-9]+\\):"
    # Example: feat(JIRA-123): Add user authentication
```

---

## IDE Integration

### Status Bar Indicator

**Purpose**: Real-time code health feedback

**Setup**:

```yaml
ide:
  status_indicator:
    enabled: true
    check_interval: 30  # seconds
    show_issue_count: true
    show_severity_icon: true
```

**Usage**:

```
Status Bar: [🟢 Code Health: Good]          # No issues
Status Bar: [🟡 Code Health: 3 warnings]    # Some issues
Status Bar: [🔴 Code Health: 2 critical]    # Critical issues

Click → Opens @codereview in Copilot chat
```

**Testing**:

```bash
# Create vulnerability
echo 'const apiKey = "sk_live_123";' > test.js

# Wait 30 seconds
# Status bar should show: 🔴 1 critical issue

# Fix it
echo 'const apiKey = process.env.API_KEY;' > test.js

# Status bar should show: 🟢 Code Health: Good
```

### Proactive Reminders

**Purpose**: Nudge developers at right moments

**Triggers**:

| Trigger | When | Message |
|---------|------|---------|
| Large changes | >500 lines | "💡 Large changes detected - run @codereview" |
| Critical path | auth/, payment/ | "🔒 Critical path requires review" |
| No review streak | 5 commits | "📊 No review in 5 commits" |
| Friday 4PM | End of week | "🎯 End of week - run @codereview!" |
| After merge | Conflicts resolved | "🔀 Verify merged code" |
| Security keywords | "auth", "password" | "🛡️ Security changes detected" |

**Configuration**:

```yaml
reminders:
  large_changes:
    enabled: true
    threshold: 500

  critical_paths:
    enabled: true

  no_review_in_n_commits:
    enabled: true
    commit_count: 5

  friday_reminder:
    enabled: true
```

---

## Team Governance

### For Large Teams (50+ Developers)

#### 1. Centralized Configuration

```yaml
# .github/codereview-config.yml (committed to repo)

# All developers use same base rules
# Team-specific overrides allowed
```

#### 2. Role-Based Rules

```yaml
teams:
  senior_devs:
    patterns: ["**/critical/**"]
    enforcement_mode: advisory  # More trust

  junior_devs:
    patterns: ["**/features/**"]
    enforcement_mode: strict  # More guidance

  contractors:
    patterns: ["**/external/**"]
    enforcement_mode: strict
    required_review_always: true
```

#### 3. Mandatory Review for Critical Code

```yaml
critical_paths:
  - pattern: "**/auth/**"
    block_without_review: true  # Cannot bypass

  - pattern: "**/payment/**"
    block_without_review: true

  - pattern: "**/admin/**"
    block_without_review: true
```

#### 4. Exemptions (Escape Hatches)

```yaml
exemptions:
  skip_paths:
    - "**/*.test.{js,ts,java,py}"
    - "**/test/**"
    - "**/generated/**"

  skip_agents:
    - pattern: "**/*.proto"
      agents: [performance, code-quality]
      reason: "Generated code"
```

---

## Metrics & Dashboards

### Track Effectiveness

```yaml
metrics:
  dashboard:
    enabled: true
    track:
      - issues_found
      - issues_fixed
      - review_frequency
      - severity_distribution

    reports:
      weekly_summary: true
      monthly_trend: true
```

### Sample Metrics

```markdown
# Weekly Code Review Report

**Week of Jan 15-22, 2026**

## Summary
- Reviews Run: 127
- Issues Found: 342
  - 🔴 Critical: 12 (blocked 12 pushes)
  - 🟠 High: 45
  - 🟡 Medium: 128
  - 🔵 Low: 157

## Issues Fixed
- Critical: 12/12 (100%) ✅
- High: 41/45 (91%)
- Medium: 89/128 (70%)

## Top Issues
1. SQL Injection - 8 instances
2. Hardcoded Credentials - 4 instances
3. N+1 Queries - 15 instances

## Team Performance
- Backend: 92% fix rate
- Frontend: 88% fix rate
- Mobile: 85% fix rate

## Trend
Issues caught in dev: ↗️ +23% vs last week
Issues reaching QA: ↘️ -67% vs last week
```

---

## Best Practices

### 1. Start Conservative, Expand Gradually

**Phase 1: Advisory Mode (Week 1-2)**
```yaml
global:
  enforcement_mode: advisory  # Warn only, don't block
```

**Phase 2: Hybrid Mode (Week 3-4)**
```yaml
global:
  enforcement_mode: hybrid  # Block critical only
```

**Phase 3: Strict Mode (Week 5+)**
```yaml
global:
  enforcement_mode: strict  # Block high and critical
```

### 2. Focus on High-Value Checks First

```yaml
# Start with these
agents:
  security:
    enabled: true
    blocking: true  # Security is critical

  bugs:
    enabled: true
    blocking: true  # Bugs cause incidents

# Add later
  code-quality:
    enabled: true
    blocking: false  # Quality improves over time

  performance:
    enabled: true
    blocking: false  # Optimize later
```

### 3. Configure Critical Paths for Your Domain

```yaml
# E-commerce
critical_paths:
  - pattern: "**/payment/**"
  - pattern: "**/checkout/**"
  - pattern: "**/cart/**"

# Healthcare
critical_paths:
  - pattern: "**/patient/**"
  - pattern: "**/phi/**"      # Protected Health Information
  - pattern: "**/hipaa/**"

# Financial
critical_paths:
  - pattern: "**/transaction/**"
  - pattern: "**/account/**"
  - pattern: "**/kyc/**"      # Know Your Customer
```

### 4. Balance Automation with Developer Experience

**Good**:
- Auto-review on push (once per push)
- Reminders for large changes
- Status bar updates every 30s

**Bad**:
- Auto-review on every file save (too frequent)
- Blocking on LOW severity (too strict)
- Notifications every 5 minutes (annoying)

### 5. Measure and Iterate

Track these metrics:

```yaml
metrics:
  - issues_caught_in_dev: Goal >90%
  - false_positive_rate: Goal <10%
  - developer_satisfaction: Goal >80%
  - time_to_fix: Goal <30min
  - bypass_rate: Goal <5%
```

If bypass rate >20% → Rules too strict
If issues still reaching prod → Rules too lenient

---

## Troubleshooting

### Issue: Hooks Not Running

**Symptoms**: Push succeeds even with vulnerabilities

**Solutions**:

```bash
# 1. Check if hooks installed
ls -la .git/hooks/

# 2. Check if executable
chmod +x .git/hooks/pre-push

# 3. Verify hooks path
git config core.hooksPath

# 4. Test manually
./.git/hooks/pre-push
```

### Issue: False Positives

**Symptoms**: Safe code flagged as issues

**Solutions**:

```yaml
# 1. Adjust severity
severity:
  overrides:
    specific_rule: LOW  # Downgrade

# 2. Add exemption
exemptions:
  skip_agents:
    - pattern: "**/specific-file.java"
      agents: [security]
      reason: "Known false positive"

# 3. Use inline suppression
# @codereview-ignore[SQL_INJECTION]: Using ORM
String query = buildQuery();
```

### Issue: Too Slow

**Symptoms**: Push takes >60 seconds

**Solutions**:

```yaml
# 1. Reduce timeout
git_hooks:
  pre_push:
    timeout: 30  # Reduce from 60

# 2. Disable less critical agents
agents:
  code-quality:
    enabled: false  # Speed up

# 3. Use haiku model (faster)
agents:
  security:
    model: haiku  # Instead of sonnet
```

### Issue: Copilot CLI Not Found

**Symptoms**: "gh copilot command not found"

**Solution**:

```bash
# Install GitHub CLI
# macOS
brew install gh

# Linux
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
sudo apt update
sudo apt install gh

# Install Copilot extension
gh extension install github/gh-copilot

# Authenticate
gh auth login
```

---

## Summary

### Shift-Left Checklist

- [ ] Install git hooks (`./.github/install-hooks.sh`)
- [ ] Configure for your team (`.github/codereview-config.yml`)
- [ ] Define critical paths (auth/, payment/, etc.)
- [ ] Set team-specific rules (backend, frontend, mobile)
- [ ] Enable IDE status indicator
- [ ] Enable proactive reminders
- [ ] Test with sample vulnerability
- [ ] Rollout to team (pilot → full)
- [ ] Track metrics (issues caught, fix rate)
- [ ] Iterate based on feedback

### Benefits You'll See

| Timeline | Expected Impact |
|----------|-----------------|
| **Week 1** | Developers aware of issues earlier |
| **Week 2** | 30% fewer issues in code review |
| **Week 4** | 50% fewer bugs reaching QA |
| **Week 8** | 70% fewer production incidents |
| **Week 12** | Measurable code quality improvement |
| **Month 6** | Cultural shift - quality-first mindset |

### Support

- Documentation: `.github/agents/README.md`
- Configuration: `.github/codereview-config.yml`
- Testing: `.github/agents/TESTING.md`
- This Guide: `.github/SHIFT-LEFT-GUIDE.md`

---

**🚀 Start catching issues earlier today!**

```bash
# Install and test
./.github/install-hooks.sh

# Create vulnerability
echo 'String pwd = "admin";' > Test.java
git add Test.java
git commit -m "test"
git push

# Watch it get blocked ✅
```
