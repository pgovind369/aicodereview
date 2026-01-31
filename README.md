# aicodereview

AI-assisted code review workflow for GitHub Copilot that analyzes diffs across all tracked git files and generates a pre-merge report using specialized agents.

## Quick Start

- For Copilot **slash commands**, type `/reviewcode` in Copilot chat. See `.github/copilot/README.md` for setup and configuration.
- For Copilot **agent mode**, type `@reviewcode` in Copilot chat. See `.github/agents/README.md` for setup and examples.

This workflow is designed to run before opening or updating a merge request so issues are fixed early.
