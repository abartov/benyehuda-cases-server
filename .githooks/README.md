# Git Hooks

This directory contains version-controlled git hooks that enforce the project's git workflow.

## Installation

After cloning the repository or pulling these hooks, run:

```bash
./.githooks/install.sh
```

This will install the hooks into your local `.git/hooks/` directory.

## Hooks

### pre-commit

Prevents direct commits to protected branches (`master`, `main`).

**Protected branches:**
- `master`
- `main`

**Override:** Use `SKIP_HOOKS=1` or `FORCE_COMMIT=1` when you need to bypass this check:
```bash
SKIP_HOOKS=1 git commit -m "your message"
# or
FORCE_COMMIT=1 git commit -m "your message"
```

### pre-push

Prevents direct pushes to protected branches.

**Protected branches:**
- `master`
- `main`
- `dragula`
- `production`
- `staging`

**Override:** Use `SKIP_HOOKS=1` or `FORCE_PUSH=1` when you need to bypass this check:
```bash
SKIP_HOOKS=1 git push
# or
FORCE_PUSH=1 git push
```

## Why These Hooks Exist

These hooks enforce the PR-based workflow required by `AGENTS.md`:

1. All changes must be made on feature/fix branches
2. All changes must be submitted via Pull Requests
3. Direct pushes to protected branches bypass code review and CI checks

## Override Use Cases

The override functionality should only be used in exceptional circumstances:

- Emergency hotfixes (though a PR is still recommended)
- Repository maintenance tasks
- Resolving git issues

**Warning:** Overriding these hooks bypasses important workflow safeguards. Use with caution and ensure you understand the implications.

## Workflow Compliance

For the complete git workflow, see `AGENTS.md` in the project root.
