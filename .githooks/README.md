# Git Hooks for Branch Protection

This directory contains documentation for git hooks that prevent accidental commits and pushes to protected branches.

**Note:** This repository uses [Overcommit](https://github.com/sds/overcommit) to manage git hooks. The protected branch checks are integrated into Overcommit alongside existing code quality checks (TrailingWhitespace, RuboCop, etc.).

## Why These Hooks Exist

This project requires all code changes to go through Pull Requests for review. The hooks automatically enforce this workflow by blocking direct commits/pushes to protected branches like `master`, `main`, `dragula`, etc.

## Installation

### Prerequisites

First, ensure Overcommit is installed:

```bash
gem install overcommit
```

Or if the project uses Bundler and Overcommit is in the Gemfile:

```bash
bundle install
```

### Install Hooks

Run the install script from the repository root:

```bash
./.githooks/install.sh
```

This script uses `overcommit --install` to set up all git hooks, including:
- Protected branch checks (pre-commit and pre-push)
- Trailing whitespace detection
- Other configured code quality checks

**Important:** Git hooks in `.git/hooks/` are not version controlled, so every clone of the repository needs to run the install script.

## What Each Hook Does

The protected branch checks are implemented as custom Overcommit hooks in `.git-hooks/`:

### pre-commit (ProtectedBranchCheck)
- Blocks commits when on protected branches (master, main, dragula, production, staging)
- Shows clear error message with proper workflow steps
- Suggests creating a feature branch before committing

### pre-push (ProtectedBranchCheck)
- Blocks pushes to protected branches
- Catches mistakes even if you committed to the wrong branch
- Provides recovery instructions if you committed to master by mistake

### Other Hooks (via Overcommit)
- **TrailingWhitespace**: Detects and prevents trailing whitespace in files
- **RuboCop**: (currently disabled) Ruby code style checking
- Additional hooks can be configured in `.overcommit.yml`

## Protected Branches

The following branches are protected by these hooks:
- `master`
- `main`
- `dragula`
- `production`
- `staging`

## Bypassing Hooks (Emergency Use Only)

In rare emergencies, you can bypass hooks with:

```bash
OVERCOMMIT_DISABLE=1 git commit  # Bypass all Overcommit hooks
git push --no-verify             # Bypass pre-push hooks
```

**⚠️ Warning:** Only use these bypass methods if you fully understand the implications and have explicit authorization.

## Proper Workflow

1. **Always** create a feature branch before starting work:
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. Make your commits on the feature branch

3. Push the feature branch:
   ```bash
   git push -u origin feature/your-feature-name
   ```

4. Create a Pull Request:
   ```bash
   gh pr create --title "Title" --body "Description"
   ```

See `AGENTS.md` for complete workflow documentation.

## Troubleshooting

**Hooks not running?**
- Verify installation: `ls -la .git/hooks/`
- Check for Overcommit signature files: `.git/hooks/overcommit-hook` and `.git/hooks/pre-commit`
- Re-run install script: `./.githooks/install.sh`
- Verify Overcommit is installed: `overcommit --version`

**Overcommit not found?**
- Install it: `gem install overcommit`
- Or if using Bundler: Add `gem 'overcommit'` to Gemfile (if not present) and run `bundle install`

**Still able to commit to master?**
- Make sure hooks are installed via Overcommit (check `.git/hooks/`)
- Check if you're using bypass flags (don't use `OVERCOMMIT_DISABLE=1` or `--no-verify`!)
- Verify you ran the install script in the correct repository
- Check `.overcommit.yml` has `ProtectedBranchCheck` enabled

## How It Works

This repository uses Overcommit to manage git hooks. Overcommit:
1. Installs wrapper scripts in `.git/hooks/`
2. Reads configuration from `.overcommit.yml`
3. Loads custom hooks from `.git-hooks/` directory
4. Runs all enabled hooks in sequence

The protected branch checks are custom Overcommit hooks that integrate seamlessly with other code quality checks.
