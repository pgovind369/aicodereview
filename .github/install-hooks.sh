#!/usr/bin/env bash
#
# GitHub Copilot Code Review - Hook Installation Script
# Installs git hooks for shift-left code review
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  GitHub Copilot Code Review - Hook Installer${NC}"
echo -e "${BLUE}  Shift-Left Development - Catch Issues Earlier${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Check if we're in a git repository
if [ ! -d ".git" ]; then
    echo -e "${RED}❌ Error: Not a git repository${NC}"
    echo -e "${YELLOW}   Run this script from the root of your git repository${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Git repository detected${NC}"

# Check if hooks directory exists
if [ ! -d ".github/hooks" ]; then
    echo -e "${RED}❌ Error: .github/hooks/ directory not found${NC}"
    echo -e "${YELLOW}   Ensure you have the code review system installed${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Code review hooks found${NC}"

# Detect OS
OS="unknown"
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    OS="linux"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    OS="macos"
elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "win32" ]]; then
    OS="windows"
fi

echo -e "${BLUE}📍 Detected OS: $OS${NC}"
echo ""

# Installation options
echo -e "${YELLOW}Choose installation method:${NC}"
echo ""
echo "  1. Symbolic links (recommended)"
echo "     Creates symlinks from .git/hooks/ to .github/hooks/"
echo "     Hooks stay in sync with repository updates"
echo ""
echo "  2. Copy files"
echo "     Copies hook files to .git/hooks/"
echo "     Requires manual update when hooks change"
echo ""
echo "  3. Configure hooks path"
echo "     Sets git core.hooksPath to .github/hooks/"
echo "     Cleanest approach, works for all developers"
echo ""

read -p "Enter choice [1-3]: " choice

case $choice in
    1)
        echo ""
        echo -e "${BLUE}Installing via symbolic links...${NC}"

        # Make hooks executable
        chmod +x .github/hooks/*

        # Create symlinks
        if [ -d ".git/hooks" ]; then
            for hook in .github/hooks/*; do
                hook_name=$(basename "$hook")

                # Skip if not a hook file
                if [[ "$hook_name" == "README.md" ]] || [[ "$hook_name" == "*.bak" ]]; then
                    continue
                fi

                # Backup existing hook
                if [ -f ".git/hooks/$hook_name" ]; then
                    echo -e "${YELLOW}  ⚠️  Backing up existing $hook_name${NC}"
                    mv ".git/hooks/$hook_name" ".git/hooks/$hook_name.backup"
                fi

                # Create symlink
                ln -sf "../../.github/hooks/$hook_name" ".git/hooks/$hook_name"
                echo -e "${GREEN}  ✓ Linked $hook_name${NC}"
            done
        fi

        echo -e "${GREEN}✅ Hooks installed via symbolic links${NC}"
        ;;

    2)
        echo ""
        echo -e "${BLUE}Installing via file copy...${NC}"

        # Make hooks executable
        chmod +x .github/hooks/*

        # Copy hooks
        for hook in .github/hooks/*; do
            hook_name=$(basename "$hook")

            # Skip if not a hook file
            if [[ "$hook_name" == "README.md" ]] || [[ "$hook_name" == "*.bak" ]]; then
                continue
            fi

            # Backup existing hook
            if [ -f ".git/hooks/$hook_name" ]; then
                echo -e "${YELLOW}  ⚠️  Backing up existing $hook_name${NC}"
                mv ".git/hooks/$hook_name" ".git/hooks/$hook_name.backup"
            fi

            # Copy file
            cp ".github/hooks/$hook_name" ".git/hooks/$hook_name"
            chmod +x ".git/hooks/$hook_name"
            echo -e "${GREEN}  ✓ Copied $hook_name${NC}"
        done

        echo -e "${GREEN}✅ Hooks installed via copy${NC}"
        echo -e "${YELLOW}⚠️  Note: You'll need to manually update hooks if they change${NC}"
        ;;

    3)
        echo ""
        echo -e "${BLUE}Configuring git hooks path...${NC}"

        # Make hooks executable
        chmod +x .github/hooks/*

        # Set hooks path
        git config core.hooksPath .github/hooks

        echo -e "${GREEN}✅ Git hooks path configured${NC}"
        echo -e "${BLUE}ℹ️  All developers will use hooks from .github/hooks/${NC}"
        ;;

    *)
        echo -e "${RED}❌ Invalid choice${NC}"
        exit 1
        ;;
esac

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✅ Installation Complete!${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Check configuration
echo -e "${BLUE}📋 Checking configuration...${NC}"
echo ""

CONFIG_FILE=".github/codereview-config.yml"
if [ -f "$CONFIG_FILE" ]; then
    echo -e "${GREEN}✓ Configuration file found${NC}"

    # Check if pre-push is enabled
    PRE_PUSH_ENABLED=$(grep -A 2 "pre_push:" "$CONFIG_FILE" | grep "enabled:" | awk '{print $2}' || echo "true")

    if [ "$PRE_PUSH_ENABLED" = "true" ]; then
        echo -e "${GREEN}✓ Pre-push hook enabled${NC}"
        echo -e "${BLUE}  → All changes will be reviewed before push${NC}"
    else
        echo -e "${YELLOW}⚠️  Pre-push hook disabled in config${NC}"
        echo -e "${YELLOW}  → Edit $CONFIG_FILE to enable${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  Configuration file not found${NC}"
    echo -e "${YELLOW}  → Using default settings${NC}"
fi

echo ""

# Check for GitHub Copilot CLI
echo -e "${BLUE}🔍 Checking GitHub Copilot CLI...${NC}"
if command -v gh &> /dev/null && gh copilot --version &> /dev/null 2>&1; then
    GH_VERSION=$(gh --version | head -1)
    echo -e "${GREEN}✓ GitHub CLI installed: $GH_VERSION${NC}"
    echo -e "${GREEN}✓ GitHub Copilot extension detected${NC}"
else
    echo -e "${YELLOW}⚠️  GitHub Copilot CLI not found${NC}"
    echo -e "${YELLOW}  → Hooks will prompt for manual @codereview${NC}"
    echo -e "${BLUE}  → Install: https://docs.github.com/en/copilot/github-copilot-in-the-cli${NC}"
fi

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}🎉 Setup Complete - Hooks Active!${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

echo -e "${BLUE}📚 What's Next:${NC}"
echo ""
echo "  1. Test the hooks:"
echo -e "     ${GREEN}echo 'test' > test.txt${NC}"
echo -e "     ${GREEN}git add test.txt${NC}"
echo -e "     ${GREEN}git commit -m 'test'${NC}"
echo -e "     ${GREEN}git push${NC}"
echo ""
echo "  2. Configure for your team:"
echo -e "     ${GREEN}vim .github/codereview-config.yml${NC}"
echo ""
echo "  3. Create a test vulnerability:"
echo -e "     ${GREEN}echo 'String password = \"admin123\";' > Test.java${NC}"
echo -e "     ${GREEN}git add Test.java && git commit -m 'test' && git push${NC}"
echo "     (Should be blocked!)"
echo ""
echo "  4. Run manual review:"
echo "     Open GitHub Copilot chat and type:"
echo -e "     ${GREEN}@codereview${NC}"
echo ""

echo -e "${BLUE}📖 Documentation:${NC}"
echo "  - Configuration: .github/codereview-config.yml"
echo "  - Usage Guide: .github/agents/README.md"
echo "  - Testing: .github/agents/TESTING.md"
echo ""

echo -e "${YELLOW}💡 Pro Tips:${NC}"
echo "  - Critical paths (auth/, payment/) are enforced automatically"
echo "  - Large changes (>500 lines) trigger automatic review"
echo "  - Use '@health-indicator' to check code health anytime"
echo "  - Bypass with 'git push --no-verify' (not recommended!)"
echo ""

echo -e "${GREEN}Happy coding with shift-left security! 🚀${NC}"
echo ""
