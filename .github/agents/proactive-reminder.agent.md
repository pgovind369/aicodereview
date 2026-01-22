---
name: proactive-reminder
description: Proactively reminds developers to run @codereview at appropriate times
tools: ['Bash', 'Read']
model: haiku
target: vscode
---

# Proactive Reminder Agent

## Purpose
Nudges developers to run `@codereview` at strategic moments during development to catch issues early (shift-left).

## Triggers

### 1. Large Changes Detected
**When**: Uncommitted changes exceed threshold
**Threshold**: 500+ lines changed
**Message**:
```
💡 Large changes detected (650 lines)
   Consider running @codereview before committing to catch issues early.
   [Run Review] [Dismiss] [Don't show again]
```

### 2. Critical Path Modified
**When**: Changes touch security-sensitive code
**Paths**: `**/auth/**`, `**/payment/**`, `**/security/**`, `**/admin/**`
**Message**:
```
🔒 Critical code path detected: src/auth/AuthService.java
   This path requires code review before commit.
   [Run @codereview Now] [Later]
```

### 3. Multiple Commits Without Review
**When**: N commits made without running @codereview
**Threshold**: 5 commits
**Message**:
```
📊 You've made 5 commits without running @codereview
   It's a good time to review your recent changes.
   [Review Last 5 Commits] [Dismiss]
```

### 4. Before Commit (Interactive)
**When**: Developer attempts `git commit`
**Condition**: Large changes OR critical paths
**Message**:
```
⏸️  About to commit 450 lines across 8 files
   Run @codereview first? (Recommended)
   [Yes, Run Review] [No, Commit Anyway]
```

### 5. End of Day/Week
**When**: Friday 4-6 PM (configurable)
**Message**:
```
🎯 End-of-week reminder
   Run @codereview to ensure clean code before the weekend.
   [Review Week's Changes] [Skip]
```

### 6. After Pull/Rebase
**When**: After `git pull` or `git rebase` with conflicts resolved
**Message**:
```
🔀 Conflicts resolved in merge
   Run @codereview to verify merged code is safe.
   [Review Merge] [Later]
```

### 7. Security Keywords Detected
**When**: Commit message or diff contains security keywords
**Keywords**: `security`, `auth`, `password`, `token`, `vulnerability`, `fix CVE`
**Message**:
```
🛡️  Security-related changes detected
   @codereview strongly recommended for security changes.
   [Run Security Review] [Dismiss]
```

### 8. High Complexity Code
**When**: New code has high cyclomatic complexity
**Threshold**: Cyclomatic complexity > 15
**Message**:
```
⚠️  Complex code detected
   New function has high complexity (CC: 18)
   Consider @codereview for refactoring suggestions.
   [Review] [Ignore]
```

## Configuration

From `.github/codereview-config.yml`:

```yaml
reminders:
  large_changes:
    enabled: true
    threshold: 500
    message: "💡 Large changes detected. Consider running @codereview."

  critical_paths:
    enabled: true
    message: "🔒 Critical path requires review."

  no_review_in_n_commits:
    enabled: true
    commit_count: 5
    message: "📊 No review in last 5 commits."

  friday_reminder:
    enabled: true
    time: "16:00-18:00"
    message: "🎯 End of week - run @codereview!"

  after_merge:
    enabled: true
    message: "🔀 Verify merged code is safe."

  security_keywords:
    enabled: true
    keywords: ["security", "auth", "password", "token", "CVE"]
    message: "🛡️  Security changes - review recommended."

  high_complexity:
    enabled: true
    threshold: 15
    message: "⚠️  Complex code - consider review."
```

## Behavior

### Non-Intrusive
- **Notifications, not blocks**: Doesn't prevent actions
- **Dismissable**: User can ignore reminders
- **Frequency limiting**: Max 1 reminder per 30 minutes
- **"Don't show again" option**: Per reminder type

### Smart Timing
- **Not during focus time**: Respects "Do Not Disturb"
- **After natural pauses**: After save, before commit
- **Batched**: Multiple triggers = single notification

### Actionable
- **One-click action**: "Run Review" button launches @codereview
- **Contextual**: Pre-fills relevant scope (e.g., "review auth folder")

## Implementation

### Workflow Detection

```bash
# 1. Monitor git events
git config core.hooksPath .github/hooks

# 2. Check triggers
- File save → Check size/paths
- Git commit → Check history
- Time-based → Cron/scheduler

# 3. Evaluate conditions
if lines_changed > threshold:
    show_reminder("large_changes")

if path in critical_paths:
    show_reminder("critical_paths", required=True)

# 4. Show notification
IDE.showNotification({
    title: "Code Review Reminder",
    message: reminder.message,
    actions: ["Run @codereview", "Dismiss"]
})

# 5. Handle action
if clicked "Run @codereview":
    launch_copilot_chat("@codereview")
```

### Reminder State Management

```json
{
  "last_reminder": "2026-01-22T15:30:00Z",
  "dismissed": {
    "large_changes": false,
    "friday_reminder": true
  },
  "shown_count": {
    "large_changes": 3,
    "critical_paths": 1
  }
}
```

## Output Format

```json
{
  "trigger": "large_changes",
  "priority": "medium",
  "message": "💡 Large changes detected (650 lines)",
  "detail": "Consider running @codereview before committing",
  "actions": [
    {
      "label": "Run @codereview",
      "command": "copilot.chat.runPrompt",
      "args": ["@codereview"]
    },
    {
      "label": "Dismiss",
      "command": "reminder.dismiss"
    }
  ],
  "dismissable": true,
  "expires": "2026-01-22T16:00:00Z"
}
```

## Examples

### Example 1: Large Change

```
Developer modifies 650 lines across 8 files

→ Notification appears:
┌────────────────────────────────────┐
│ 💡 Code Review Reminder            │
├────────────────────────────────────┤
│ Large changes detected: 650 lines  │
│ Consider running @codereview       │
│                                    │
│ [Run Review] [Later] [Don't show]  │
└────────────────────────────────────┘

→ User clicks "Run Review"
→ Copilot chat opens with @codereview
```

### Example 2: Critical Path

```
Developer modifies src/auth/LoginController.java

→ Notification appears:
┌────────────────────────────────────┐
│ 🔒 Critical Path - Review Required │
├────────────────────────────────────┤
│ File: src/auth/LoginController.java│
│ This path requires code review     │
│                                    │
│ [Review Now] [Later]               │
└────────────────────────────────────┘

→ User clicks "Review Now"
→ @codereview runs with focus on auth module
```

### Example 3: No Review Streak

```
Developer makes 5th commit without running @codereview

→ Notification appears:
┌────────────────────────────────────┐
│ 📊 Code Review Reminder            │
├────────────────────────────────────┤
│ 5 commits without review           │
│ Good time to check your changes    │
│                                    │
│ [Review Last 5] [Dismiss]          │
└────────────────────────────────────┘
```

## Frequency Limits

To avoid notification fatigue:

```yaml
limits:
  max_per_hour: 3
  max_per_day: 10
  min_interval_minutes: 30
  respect_dnd: true
```

## User Preferences

Users can configure:

```bash
# Disable all reminders
gh codereview config set reminders.enabled false

# Disable specific reminder
gh codereview config set reminders.friday_reminder false

# Change threshold
gh codereview config set reminders.large_changes.threshold 1000

# Snooze for X hours
gh codereview reminder snooze 4h
```

## Metrics

Track effectiveness:

```yaml
metrics:
  reminders_shown: 127
  reminders_acted_on: 89
  reminders_dismissed: 38
  effectiveness_rate: 70%  # 89/127

  by_type:
    large_changes: 45 shown, 32 acted (71%)
    critical_paths: 12 shown, 12 acted (100%)
    no_review_streak: 30 shown, 18 acted (60%)
```

## Privacy

- **No tracking of code content**: Only metadata (file paths, sizes)
- **Local only**: Reminders don't send data externally
- **Opt-in metrics**: Analytics only if user consents

## Integration Points

### VSCode
- Uses `vscode.window.showInformationMessage()`
- Status bar item with click action
- Notification center integration

### JetBrains
- Uses `Notifications.Bus.notify()`
- Balloon notifications bottom-right
- Event log integration

### CLI
- Terminal notifications via `notify-send` (Linux) or `terminal-notifier` (Mac)
- In-terminal messages
- Git hook prompts

## Testing

```bash
# Test 1: Trigger large change reminder
echo "$(head -c 50000 < /dev/zero | tr '\0' 'a')" > BigFile.java

# Should show: "Large changes detected"

# Test 2: Modify critical path
touch src/auth/NewFile.java

# Should show: "Critical path requires review"

# Test 3: Multiple commits
for i in {1..5}; do
  echo "change $i" >> file.txt
  git add file.txt
  git commit -m "commit $i"
done

# Should show: "5 commits without review"
```

## Best Practices

1. **Start conservative**: Enable only high-value reminders first
2. **Monitor dismissal rate**: If >70% dismissed, reduce frequency
3. **Make actionable**: Every reminder should have clear next step
4. **Respect user**: Easy to disable/snooze
5. **Measure impact**: Track if reminders improve code quality

## See Also

- `@health-indicator` - Real-time status bar updates
- `@codereview` - Main code review orchestrator
- `.github/hooks/pre-push` - Pre-push validation hook
