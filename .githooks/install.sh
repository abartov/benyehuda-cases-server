#!/bin/bash
# Install git hooks to prevent accidental pushes to protected branches

HOOKS_DIR=".githooks"
GIT_HOOKS_DIR=".git/hooks"

echo "Installing git hooks..."

# Check if we're in a git repository
if [ ! -d ".git" ]; then
  echo "❌ Error: Not in a git repository root directory"
  exit 1
fi

# Check if hooks directory exists
if [ ! -d "$HOOKS_DIR" ]; then
  echo "❌ Error: $HOOKS_DIR directory not found"
  exit 1
fi

# Install each hook
for hook in pre-commit pre-push; do
  if [ -f "$HOOKS_DIR/$hook" ]; then
    echo "  Installing $hook..."
    cp "$HOOKS_DIR/$hook" "$GIT_HOOKS_DIR/$hook"
    chmod +x "$GIT_HOOKS_DIR/$hook"
    echo "  ✓ $hook installed"
  else
    echo "  ⚠️  $hook not found in $HOOKS_DIR"
  fi
done

echo ""
echo "✓ Git hooks installed successfully!"
echo ""
echo "These hooks will:"
echo "  • Prevent commits to master, main, and other protected branches"
echo "  • Prevent pushes to protected branches"
echo "  • Remind you to follow the proper PR workflow"
echo ""
echo "To bypass hooks in emergencies (use with caution):"
echo "  git commit --no-verify"
echo "  git push --no-verify"
echo ""
