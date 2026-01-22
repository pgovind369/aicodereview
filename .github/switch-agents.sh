#!/usr/bin/env bash
#
# Switch between original and simplified agent systems
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  GitHub Copilot Code Review - Agent Switcher${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Detect current version
if [ -d ".github/agents" ] && [ -f ".github/agents/security.agent.md" ]; then
    CURRENT="original"
    echo -e "${GREEN}✓ Currently using: Original (6 agents, verbose)${NC}"
elif [ -d ".github/agents" ] && [ -f ".github/agents/security-owasp.agent.md" ]; then
    CURRENT="simplified"
    echo -e "${GREEN}✓ Currently using: Simplified (5 agents, concise)${NC}"
else
    CURRENT="unknown"
    echo -e "${YELLOW}⚠️  Cannot detect current version${NC}"
fi

echo ""

# Show comparison
cat << EOF
┌────────────────────────────────────────────────────────────┐
│                   Version Comparison                        │
├────────────────────────────────────────────────────────────┤
│                                                             │
│  ORIGINAL                      SIMPLIFIED                  │
│  ────────────────────────      ───────────────────────     │
│  • 6 agents                    • 5 agents                  │
│  • Verbose (200-600 lines)     • Concise (80 lines)        │
│  • 45s per review              • 25s per review            │
│  • \$0.23 per review            • \$0.12 per review         │
│  • Detailed examples           • Pattern-focused           │
│  • 13,200 prompt tokens        • 4,500 prompt tokens       │
│                                                             │
│  Best for:                     Best for:                   │
│  - Learning                    - Production use            │
│  - Training new devs           - Cost optimization         │
│  - Detailed context            - Speed                     │
│                                                             │
└────────────────────────────────────────────────────────────┘

EOF

echo -e "${YELLOW}What would you like to do?${NC}"
echo ""
echo "  1. Switch to Simplified (faster, cheaper)"
echo "  2. Switch to Original (detailed, verbose)"
echo "  3. View current system info"
echo "  4. Test current system"
echo "  5. Compare both (run test on both versions)"
echo "  6. Exit"
echo ""

read -p "Enter choice [1-6]: " choice

case $choice in
    1)
        echo ""
        echo -e "${BLUE}Switching to Simplified version...${NC}"

        if [ "$CURRENT" = "simplified" ]; then
            echo -e "${YELLOW}Already using simplified version!${NC}"
            exit 0
        fi

        # Backup original if exists
        if [ -d ".github/agents" ]; then
            echo -e "${BLUE}📦 Backing up original to .github/agents-original${NC}"
            rm -rf .github/agents-original
            mv .github/agents .github/agents-original
        fi

        # Activate simplified
        if [ ! -d ".github/agents-simplified" ]; then
            echo -e "${RED}❌ Error: .github/agents-simplified not found${NC}"
            echo -e "${YELLOW}   Restoring original...${NC}"
            mv .github/agents-original .github/agents
            exit 1
        fi

        cp -r .github/agents-simplified .github/agents
        echo -e "${GREEN}✅ Switched to simplified version${NC}"
        echo ""
        echo -e "${GREEN}Benefits unlocked:${NC}"
        echo "  • 48% cost reduction ($0.23 → $0.12 per review)"
        echo "  • 44% faster (45s → 25s per review)"
        echo "  • 66% fewer prompt tokens"
        echo ""
        echo -e "${BLUE}To rollback: ./switch-agents.sh and choose option 2${NC}"
        ;;

    2)
        echo ""
        echo -e "${BLUE}Switching to Original version...${NC}"

        if [ "$CURRENT" = "original" ]; then
            echo -e "${YELLOW}Already using original version!${NC}"
            exit 0
        fi

        # Backup simplified if exists
        if [ -d ".github/agents" ]; then
            echo -e "${BLUE}📦 Backing up simplified to .github/agents-simplified-backup${NC}"
            rm -rf .github/agents-simplified-backup
            mv .github/agents .github/agents-simplified-backup
        fi

        # Activate original
        if [ ! -d ".github/agents-original" ]; then
            echo -e "${RED}❌ Error: .github/agents-original not found${NC}"
            echo -e "${YELLOW}   Restoring simplified...${NC}"
            mv .github/agents-simplified-backup .github/agents
            exit 1
        fi

        cp -r .github/agents-original .github/agents
        echo -e "${GREEN}✅ Switched to original version${NC}"
        echo ""
        echo -e "${GREEN}Features:${NC}"
        echo "  • Verbose examples for learning"
        echo "  • Detailed security guidance"
        echo "  • Comprehensive OWASP mapping"
        echo ""
        echo -e "${BLUE}To switch back: ./switch-agents.sh and choose option 1${NC}"
        ;;

    3)
        echo ""
        echo -e "${BLUE}Current System Information:${NC}"
        echo ""

        if [ -d ".github/agents" ]; then
            AGENT_COUNT=$(ls .github/agents/*.agent.md 2>/dev/null | wc -l | tr -d ' ')
            echo "  Agents directory: .github/agents/"
            echo "  Agent count: $AGENT_COUNT"
            echo "  Agents:"
            ls .github/agents/*.agent.md 2>/dev/null | xargs -n1 basename | sed 's/^/    - /'
        else
            echo -e "${RED}  No agents directory found!${NC}"
        fi

        echo ""

        if [ -d ".github/agents-original" ]; then
            echo -e "${GREEN}  ✓ Original backup available${NC}"
        fi

        if [ -d ".github/agents-simplified" ]; then
            echo -e "${GREEN}  ✓ Simplified version available${NC}"
        fi
        ;;

    4)
        echo ""
        echo -e "${BLUE}Testing current system...${NC}"
        echo ""

        # Create test file
        cat > /tmp/CodeReviewTest.java << 'EOF'
package com.test;
public class CodeReviewTest {
    private String password = "admin123";
    public void query(String id) {
        String sql = "SELECT * FROM users WHERE id = " + id;
    }
}
EOF

        echo "Test file created: /tmp/CodeReviewTest.java"
        echo ""
        echo -e "${YELLOW}To test:${NC}"
        echo "  1. Copy /tmp/CodeReviewTest.java to your repo"
        echo "  2. Run: git add CodeReviewTest.java"
        echo "  3. Open Copilot chat and type: @codereview"
        echo ""
        echo "Expected findings:"
        echo "  • CRITICAL: Hardcoded password"
        echo "  • CRITICAL: SQL injection"
        echo ""
        echo -e "${BLUE}Press Enter to continue...${NC}"
        read
        ;;

    5)
        echo ""
        echo -e "${BLUE}Comparing both versions...${NC}"
        echo ""
        echo "This will run the same test with both systems."
        echo ""

        # Create test file
        cat > /tmp/ComparisonTest.java << 'EOF'
package com.test;
public class ComparisonTest {
    private String apiKey = "sk_live_12345";
    public User getUser(String id) {
        String query = "SELECT * FROM users WHERE id = " + id;
        return db.execute(query);
    }
}
EOF

        echo "Test file: /tmp/ComparisonTest.java"
        echo ""
        echo -e "${YELLOW}Instructions:${NC}"
        echo ""
        echo "1. Copy test file to repo: cp /tmp/ComparisonTest.java ."
        echo "2. git add ComparisonTest.java"
        echo ""
        echo "3. Test with CURRENT system:"
        echo "   - Run @codereview"
        echo "   - Record: Time, Issues, Cost"
        echo ""
        echo "4. Switch versions: ./switch-agents.sh"
        echo ""
        echo "5. Test with OTHER system:"
        echo "   - Run @codereview again"
        echo "   - Record: Time, Issues, Cost"
        echo ""
        echo "6. Compare results in .github/test-results/comparison.md"
        echo ""
        echo -e "${BLUE}See .github/TESTING-COMPARISON.md for full guide${NC}"
        ;;

    6)
        echo ""
        echo "Exiting without changes."
        exit 0
        ;;

    *)
        echo -e "${RED}Invalid choice${NC}"
        exit 1
        ;;
esac

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✓ Operation completed${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
