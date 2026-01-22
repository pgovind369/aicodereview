# Code Review System - Optimization Guide
## Token Usage & Performance Optimization

**Current Performance**: 30-50 seconds, $0.23/review
**Optimized Target**: 15-25 seconds, $0.08/review (65% cost reduction)

---

## 📊 Current State Analysis

### Token Usage (Medium 500-line diff)
```
System prompts (5 agents):  13,200 tokens (40%)
Code diff context (×5):      8,600 tokens (26%)
Output findings (×5):       11,000 tokens (34%)
─────────────────────────────────────────────
TOTAL:                      32,800 tokens

Cost: $0.23 per review
```

### Time Breakdown
```
Git operations:              3-5s
Agent execution (parallel): 20-35s
Report aggregation:          5s
─────────────────────────────
TOTAL:                      30-50s
```

### Cost at Scale (100 developers)
```
Reviews per day: 100 devs × 10 reviews = 1,000 reviews
Cost per day:    1,000 × $0.23 = $230/day
Cost per month:  $230 × 30 = $6,900/month
Cost per year:   $82,800/year
```

---

## 🎯 Optimization Phases

### Phase 1: Quick Wins (2 days) - 35% cost reduction

#### 1.1 Enable Prompt Caching ⚡ (Highest Impact)

**Problem**: 13,200 tokens of agent instructions sent every review
**Solution**: Use Claude's prompt caching (90% discount on cached tokens)

**Implementation**:

Update each agent file to separate cached instructions from dynamic diff:

```yaml
# .github/agents/security.agent.md
---
name: security
description: Detect security vulnerabilities
tools: ['Bash', 'Read', 'Grep', 'Glob']
model: sonnet
target: vscode
cache_sections:
  - name: instructions
    cache_ttl: 3600  # 1 hour
---

# CACHED SECTION START
# Security Review Agent

## Purpose
[All static instructions go here - will be cached]

## Review Checklist
[Static checklists]

## Language-Specific Checks
[Static examples]

## Output Format
[Static format]

# CACHED SECTION END

---

# DYNAMIC SECTION (Not Cached)
## Code Diff to Analyze
{diff content - changes each review}
```

**Impact**:
- **Before**: 13,200 tokens × $3/MTok = $0.040/review
- **After**: 13,200 tokens × $0.30/MTok = $0.004/review (cached)
- **Savings**: $0.036 per review × 30k reviews/month = **$1,080/month**

**Claude API Configuration**:
```python
# When calling Anthropic API
response = anthropic.messages.create(
    model="claude-sonnet-3-5",
    system=[
        {
            "type": "text",
            "text": agent_instructions,
            "cache_control": {"type": "ephemeral"}  # Cache this
        },
        {
            "type": "text",
            "text": code_diff  # Don't cache - changes each time
        }
    ],
    messages=[...]
)
```

---

#### 1.2 Compress Agent Prompts (30% reduction)

**Problem**: Agent files are 200-600 lines with verbose examples
**Solution**: Extract examples to shared library, use concise instructions

**Before** (security.agent.md - 232 lines):
```markdown
### Java/Kotlin
```java
// CRITICAL: SQL Injection
String query = "SELECT * FROM users WHERE id = " + userId; // ❌
PreparedStatement stmt = conn.prepareStatement("SELECT * FROM users WHERE id = ?"); // ✅

// CRITICAL: Command Injection
Runtime.getRuntime().exec("ping " + userInput); // ❌
ProcessBuilder pb = new ProcessBuilder("ping", userInput); // ✅

[50 more examples...]
```

**After** (security.agent.md - 120 lines):
```markdown
### Java/Kotlin
Check for:
- SQL Injection: String concatenation in queries
- Command Injection: Runtime.exec with user input
- Weak Crypto: MD5, SHA1, insecure Random

Examples: See .github/agents/examples/security-java.md
```

**Implementation**:
```bash
mkdir -p .github/agents/examples/

# Move detailed examples to separate files
.github/agents/examples/
  ├── security-java.md
  ├── security-javascript.md
  ├── security-python.md
  ├── bugs-patterns.md
  └── performance-antipatterns.md

# Agents reference these but don't include full content
```

**Impact**:
- **Reduction**: 600 lines → 200 lines per agent
- **Token savings**: ~4,000 tokens per review (30%)
- **Cost savings**: $0.02 per review = $600/month

---

#### 1.3 Optimize Pre-Push Hook

**Problem**: O(N×M) nested loops checking critical paths
**Solution**: Single-pass awk processing

**Before** (.github/hooks/pre-push lines 82-113):
```bash
# Nested loops - inefficient
while IFS= read -r line; do
    if echo "$line" | grep -q "pattern:"; then
        PATTERN=$(echo "$line" | sed 's/.*pattern: "\(.*\)".*/\1/')
        GREP_PATTERN=$(echo "$PATTERN" | sed 's/\*\*/.*/' | sed 's/\*/[^\/]*/')
        while IFS= read -r file; do
            if echo "$file" | grep -qE "$GREP_PATTERN"; then
                CRITICAL_FILES="$CRITICAL_FILES\n  🔒 $file"
            fi
        done <<< "$CHANGED_FILES"
    fi
done < <(sed -n '/^critical_paths:/,/^[^ ]/p' "$CONFIG_FILE")
```

**After**:
```bash
# Single-pass processing
CRITICAL_FILES=$(awk -v changed_files="$CHANGED_FILES" '
BEGIN {
    split(changed_files, files, "\n")
}
/pattern:/ {
    gsub(/.*pattern: "/, ""); gsub(/".*/, "")
    pattern = $0

    # Convert glob to regex
    gsub(/\*\*/, "DOUBLESTAR", pattern)
    gsub(/\*/, "[^/]*", pattern)
    gsub(/DOUBLESTAR/, ".*", pattern)

    for (i in files) {
        if (files[i] ~ pattern) {
            print "🔒 " files[i]
        }
    }
}
' "$CONFIG_FILE" | sort -u)
```

**Impact**:
- **Before**: 100 files × 5 patterns = 500 operations
- **After**: 1 pass through config file
- **Time saved**: 2-3 seconds per push

---

### Phase 1 Results
```
Cost per review:  $0.23 → $0.15 (-35%)
Monthly cost:     $6,900 → $4,500 (-$2,400)
Annual savings:   $28,800
Implementation:   2 days
ROI:             144x (savings/effort)
```

---

## Phase 2: Structural Changes (5 days) - Additional 25% reduction

#### 2.1 Merge Security + OWASP Agents

**Problem**: 60% overlap between security.agent.md and owasp.agent.md
**Solution**: Single comprehensive security agent

**Create** `.github/agents/security-comprehensive.agent.md`:

```markdown
---
name: security-comprehensive
description: Detect security vulnerabilities mapped to OWASP Top 10
tools: ['Bash', 'Read', 'Grep', 'Glob']
model: sonnet
---

# Security & OWASP Review Agent

## Detection Categories

### 1. Authentication & Authorization
Maps to: OWASP A01:2021 - Broken Access Control

[Combined checks from both agents]

### 2. Injection Vulnerabilities
Maps to: OWASP A03:2021 - Injection

[Combined checks]

### 3. Cryptographic Failures
Maps to: OWASP A02:2021 - Cryptographic Failures

[Combined checks]

## Output Format
For each finding, provide:
- Issue description
- OWASP category mapping (A01-A10)
- CWE ID
- Severity
- Fix

[Rest of agent...]
```

**Update orchestrator** `.github/agents/codereview.agent.md`:
```yaml
handoffs: ['security-comprehensive', 'bugs', 'code-quality', 'performance']
# Removed separate 'security' and 'owasp' - now combined
```

**Impact**:
- **Agents**: 5 → 4 (-20%)
- **Duplicate work eliminated**: 60% of security agent
- **Token savings**: 3,500 tokens per review
- **Cost savings**: $0.05 per review = $1,500/month
- **Time saved**: Parallel execution still fast, but less API overhead

---

#### 2.2 Implement Smart Agent Selection

**Problem**: Running all agents even when not relevant
**Solution**: Route code to relevant agents based on file type and patterns

**Create** `.github/agents/agent-router.agent.md`:

```markdown
---
name: agent-router
description: Intelligently route code changes to relevant review agents
tools: ['Bash', 'Grep', 'Glob']
model: haiku  # Fast, cheap model for routing
---

# Agent Router

## Routing Logic

### Security-Comprehensive Agent
Run if ANY:
- Files in critical paths: auth/, payment/, security/, admin/
- Security keywords in diff: password, token, secret, api_key
- Authentication code: login, oauth, jwt, session
- Crypto operations: encrypt, decrypt, hash, random

### Bugs Agent
Run if ANY:
- Business logic code (not config/docs)
- New functions added
- Control flow changes (if/else/loops)
- Exception handling modified

### Code Quality Agent
Run if ANY:
- Functions > 50 lines
- New classes
- Complexity indicators (nested loops, deep conditionals)

### Performance Agent
Run if ANY:
- Database queries (SELECT, INSERT, UPDATE)
- Loops with > 10 iterations
- API calls
- File I/O operations
- Caching code

## Output
Return: List of agents to invoke for this diff
```

**Update orchestrator**:
```yaml
Phase 2: Smart Agent Delegation

1. Run @agent-router (fast, cheap Haiku model)
2. Get list of relevant agents
3. Run only those agents in parallel
4. Skip irrelevant agents

Example:
- Config file changes → Skip all agents (no code review needed)
- Test file changes → Run bugs + code-quality only
- Auth file changes → Run ALL agents
```

**Impact**:
- **Average agents per review**: 5 → 3.5 (-30%)
- **Token savings**: 6,500 tokens per review (on non-critical changes)
- **Cost savings**: $0.04 per review = $1,200/month
- **Time saved**: Skip 1-2 agents = ~10 seconds

---

#### 2.3 Implement Diff Chunking

**Problem**: Sending entire diff to every agent (duplicate data)
**Solution**: Send only relevant code sections to each agent

**Create** `.github/agents/diff-chunker.agent.md`:

```markdown
---
name: diff-chunker
description: Split diff into relevant chunks for each agent
tools: ['Bash', 'Grep']
model: haiku
---

# Diff Chunker

## Purpose
Reduce token usage by sending only relevant code to each agent.

## Chunking Strategy

### For Security Agent
Extract:
- Functions with user input parameters
- Database queries
- Authentication/authorization code
- Crypto operations
- File system operations
- Network calls

Skip:
- UI rendering code
- Formatting changes
- Comments
- Test assertions

### For Bugs Agent
Extract:
- Business logic functions
- Control flow (if/else/loops)
- Error handling (try/catch)
- State management

Skip:
- Type definitions
- Imports
- Constants
- UI code

### For Performance Agent
Extract:
- Database queries
- Loops
- API calls
- Caching logic
- Data transformations

Skip:
- One-time initialization
- UI rendering
- Test setup

## Output
For each agent, return:
- Relevant code chunks
- Context (file name, line numbers)
- Excluded sections count
```

**Impact**:
- **Token reduction**: 40-50% per agent (send only relevant code)
- **Example**: 2000-line diff → 400 lines to security agent
- **Cost savings**: $0.06 per review = $1,800/month

---

### Phase 2 Results
```
Cost per review:  $0.15 → $0.10 (-33% additional)
Monthly cost:     $4,500 → $3,000 (-$1,500)
Cumulative savings: $46,800/year (vs original)
Implementation:   5 days
```

---

## Phase 3: Advanced Features (2 weeks) - Additional 20% reduction

#### 3.1 Incremental Review with Caching

**Problem**: Re-reviewing unchanged code on every review
**Solution**: Cache findings per file hash, only review changed files

**Create** `.github/codereview-cache.json`:

```json
{
  "version": "1.0",
  "last_review": "2026-01-22T10:30:00Z",
  "last_commit": "abc123def456",
  "files": {
    "src/auth/LoginService.java": {
      "hash": "a1b2c3d4",
      "last_reviewed": "2026-01-22T10:30:00Z",
      "findings": [
        {
          "agent": "security",
          "severity": "HIGH",
          "type": "weak_session",
          "line": 45,
          "message": "Session timeout too long"
        }
      ]
    },
    "src/payment/PaymentProcessor.java": {
      "hash": "e5f6g7h8",
      "last_reviewed": "2026-01-22T10:30:00Z",
      "findings": []
    }
  }
}
```

**Update orchestrator**:

```markdown
## Phase 1: Incremental Change Detection

1. Load cache from .github/codereview-cache.json
2. For each changed file:
   a. Calculate file hash
   b. Compare with cached hash
   c. If hash matches → Use cached findings
   d. If hash differs → Mark for review
3. Only send changed files to agents
4. Merge cached + new findings in final report
```

**Implementation**:

```bash
# In pre-push hook
for file in $CHANGED_FILES; do
    CURRENT_HASH=$(git hash-object "$file")
    CACHED_HASH=$(jq -r ".files[\"$file\"].hash" .github/codereview-cache.json 2>/dev/null || echo "")

    if [ "$CURRENT_HASH" != "$CACHED_HASH" ]; then
        FILES_TO_REVIEW="$FILES_TO_REVIEW $file"
    else
        echo "✓ $file unchanged - using cached findings"
    fi
done
```

**Impact**:
- **Re-review scenario**: Change 2 files out of 20 → Review only 2 (90% reduction)
- **Token savings**: 28,000 tokens on typical re-review
- **Cost savings**: $0.18 per re-review
- **Assumption**: 40% of reviews are re-reviews
- **Monthly savings**: 12,000 re-reviews × $0.18 = $2,160/month

---

#### 3.2 Result Deduplication

**Problem**: Agents report the same issue (e.g., both security and bugs find null pointer)
**Solution**: Deduplicate findings across agents

**Create** `.github/agents/deduplicator.agent.md`:

```markdown
## Deduplication Algorithm

1. Collect all findings from all agents
2. For each finding pair:
   - Same file + line → Check similarity
   - Same severity + category → Likely duplicate
   - Levenshtein distance of descriptions < 0.8 → Duplicate
3. Keep highest severity version
4. Merge references from duplicates
5. Return deduplicated list
```

**Impact**:
- **Duplicate rate**: ~15% of findings
- **Cleaner reports**: Fewer repeated issues
- **Developer experience**: Less noise

---

#### 3.3 Use Haiku for Low-Stakes Agents

**Problem**: Using expensive Sonnet model for all agents
**Solution**: Use cheaper Haiku for code-quality and initial triage

```yaml
# Update agent models
agents:
  security-comprehensive:
    model: sonnet  # Keep Sonnet - security critical

  bugs:
    model: sonnet  # Keep Sonnet - bugs critical

  code-quality:
    model: haiku   # Switch to Haiku - quality less critical

  performance:
    model: haiku   # Switch to Haiku - performance suggestions

  agent-router:
    model: haiku   # Fast routing

  diff-chunker:
    model: haiku   # Fast chunking
```

**Haiku Pricing**:
- Input: $0.25/MTok (vs $3/MTok for Sonnet) = 12x cheaper
- Output: $1.25/MTok (vs $15/MTok for Sonnet) = 12x cheaper

**Impact**:
- **Code-quality + performance**: 7,000 tokens input + 4,000 output
  - **Before**: (7k × $3 + 4k × $15) / 1M = $0.081
  - **After**: (7k × $0.25 + 4k × $1.25) / 1M = $0.007
  - **Savings**: $0.074 per review = $2,220/month

---

### Phase 3 Results
```
Cost per review:  $0.10 → $0.08 (-20% additional)
Full reviews:     18,000 × $0.10 = $1,800/month
Incremental:      12,000 × $0.02 = $240/month
Monthly cost:     $2,040/month
Annual cost:      $24,480/year

TOTAL SAVINGS: $58,320/year (71% reduction vs original)
```

---

## 📈 Summary: Complete Optimization Journey

| Phase | Time | Cost/Review | Monthly Cost | Annual Savings |
|-------|------|-------------|--------------|----------------|
| **Current** | 45s | $0.23 | $6,900 | - |
| **Phase 1** | 38s | $0.15 | $4,500 | $28,800 |
| **Phase 2** | 28s | $0.10 | $3,000 | $46,800 |
| **Phase 3** | 20s | $0.08* | $2,040 | $58,320 |

*Blended rate (60% full reviews at $0.10, 40% incremental at $0.02)

---

## 🎯 Recommended Implementation Path

### Week 1-2: Phase 1 (Immediate Value)
```bash
# Day 1: Enable prompt caching
- Update all agent files with cache_sections
- Test with sample review
- Deploy to staging

# Day 2: Compress prompts + optimize hooks
- Extract examples to separate files
- Rewrite pre-push hook with awk
- Benchmark improvements

# Expected: $2,400/month savings unlocked
```

### Week 3-4: Phase 2 (Structural)
```bash
# Day 1-2: Merge security + OWASP
- Create security-comprehensive.agent.md
- Update orchestrator
- Test coverage parity

# Day 3-4: Smart routing
- Create agent-router.agent.md
- Implement diff-chunker
- Test on various file types

# Expected: Additional $1,500/month savings
```

### Month 2: Phase 3 (Advanced)
```bash
# Week 1: Incremental caching
- Design cache schema
- Implement file hash tracking
- Build merge logic

# Week 2: Haiku migration + dedup
- Switch code-quality to Haiku
- Switch performance to Haiku
- Implement deduplicator

# Expected: Additional $2,860/month savings
```

---

## 🧪 Testing Optimization Impact

### Test Script
```bash
#!/bin/bash
# .github/test-optimization.sh

echo "Testing optimization impact..."

# Test 1: Small diff (100 lines)
git checkout -b test-small
echo "test" > small.txt
git add small.txt
time gh copilot suggest "@codereview"

# Test 2: Medium diff (500 lines)
git checkout -b test-medium
# Generate 500-line change
time gh copilot suggest "@codereview"

# Test 3: Large diff (2000 lines)
git checkout -b test-large
# Generate 2000-line change
time gh copilot suggest "@codereview"

# Compare before/after times and token usage
```

### Metrics to Track
```yaml
metrics:
  before_optimization:
    avg_time_seconds: 45
    avg_tokens: 32800
    avg_cost_usd: 0.23

  after_phase_1:
    avg_time_seconds: 38
    avg_tokens: 22000
    avg_cost_usd: 0.15
    improvement: "35% cost, 15% time"

  after_phase_2:
    avg_time_seconds: 28
    avg_tokens: 16000
    avg_cost_usd: 0.10
    improvement: "56% cost, 38% time"

  after_phase_3:
    avg_time_seconds: 20
    avg_tokens_full: 14000
    avg_tokens_incremental: 3000
    avg_cost_usd: 0.08
    improvement: "65% cost, 56% time"
```

---

## ⚠️ Trade-offs & Considerations

### Caching Trade-offs
**Pro**: 90% cost reduction on cached prompts
**Con**: Cache invalidation after 1 hour (configurable)
**Mitigation**: Acceptable - agent instructions rarely change

### Merged Agents Trade-offs
**Pro**: Less duplication, cleaner reports
**Con**: Single agent failure loses both security and OWASP
**Mitigation**: Robust error handling, fallback to individual agents

### Haiku for Quality Trade-offs
**Pro**: 12x cheaper
**Con**: Slightly less nuanced analysis
**Mitigation**: Keep Sonnet for critical (security/bugs), Haiku for advisory

### Incremental Caching Trade-offs
**Pro**: 80% faster on re-reviews
**Con**: Cache invalidation complexity
**Mitigation**: Conservative cache invalidation (file hash + dependencies)

---

## 📊 ROI Analysis

### Investment
```
Phase 1: 2 days × $1,000/day = $2,000
Phase 2: 5 days × $1,000/day = $5,000
Phase 3: 10 days × $1,000/day = $10,000
─────────────────────────────────────
Total Investment: $17,000
```

### Return
```
Annual Savings: $58,320
Payback Period: 3.5 months
3-Year ROI: ($58,320 × 3 - $17,000) / $17,000 = 928%
```

---

## 🚀 Next Steps

1. **Prioritize**: Choose phase based on urgency
   - Need quick wins? → Start with Phase 1
   - Have time for structural? → Do Phase 2
   - Want maximum savings? → Full implementation

2. **Test**: Run optimization tests with sample reviews

3. **Deploy**: Start with staging, then production

4. **Monitor**: Track metrics before/after

5. **Iterate**: Tune based on real-world usage

---

**Questions? See `.github/agents/README.md` or open an issue.**
