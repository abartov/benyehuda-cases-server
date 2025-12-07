# Git Hooks for Branch Protection

This directory contains git hooks that prevent accidental commits and pushes to protected branches.

## Why These Hooks Exist

This project requires all code changes to go through Pull Requests for review. The hooks automatically enforce this workflow by blocking direct commits/pushes to protected branches like `master`, `main`, `dragula`, etc.

## Installation

Run the install script from the repository root:

```bash
./.githooks/install.sh
```

This copies the hooks to `.git/hooks/` and makes them executable.

**Important:** Git hooks in `.git/hooks/` are not version controlled, so every clone of the repository needs to run the install script.

## What Each Hook Does

### pre-commit
- Blocks commits when on protected branches (master, main, dragula, production, staging)
- Shows clear error message with proper workflow steps
- Suggests creating a feature branch before committing

### pre-push
- Blocks pushes to protected branches
- Catches mistakes even if you committed to the wrong branch
- Provides recovery instructions if you committed to master by mistake

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
git commit --no-verify
git push --no-verify
```

**⚠️ Warning:** Only use `--no-verify` if you fully understand the implications and have explicit authorization.

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
- Verify installation: `ls -la .git/hooks/pre-commit .git/hooks/pre-push`
- Check they're executable: `ls -l .git/hooks/pre-*`
- Re-run install script: `./.githooks/install.sh`

**Still able to commit to master?**
- Make sure hooks are installed (they're in `.git/hooks/`, not `.githooks/`)
- Check if you're using `--no-verify` (don't!)
- Verify you ran the install script in the correct repository
