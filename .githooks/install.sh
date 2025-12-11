#!/bin/bash
# Install git hooks from .githooks/ to .git/hooks/

set -e

HOOKS_DIR=".githooks"
GIT_HOOKS_DIR=".git/hooks"

echo "Installing git hooks..."

# Check if we're in a git repository
if [ ! -d ".git" ]; then
  echo "Error: Not in a git repository root"
  exit 1
fi

# Check if .githooks directory exists
if [ ! -d "$HOOKS_DIR" ]; then
  echo "Error: $HOOKS_DIR directory not found"
  exit 1
fi

# Install each hook
for hook in "$HOOKS_DIR"/*; do
  # Skip install.sh and README.md
  if [[ "$hook" == *"install.sh" ]] || [[ "$hook" == *"README.md" ]]; then
    continue
  fi

  hook_name=$(basename "$hook")

  # Skip if not a file
  if [ ! -f "$hook" ]; then
    continue
  fi

  # Create backup if hook already exists
  if [ -f "$GIT_HOOKS_DIR/$hook_name" ]; then
    echo "  Backing up existing $hook_name to $hook_name.backup"
    cp "$GIT_HOOKS_DIR/$hook_name" "$GIT_HOOKS_DIR/$hook_name.backup"
  fi

  # Copy hook and make executable
  echo "  Installing $hook_name"
  cp "$hook" "$GIT_HOOKS_DIR/$hook_name"
  chmod +x "$GIT_HOOKS_DIR/$hook_name"
done

echo ""
echo "✅ Git hooks installed successfully!"
echo ""
echo "Installed hooks:"
for hook in "$HOOKS_DIR"/*; do
  if [[ "$hook" != *"install.sh" ]] && [[ "$hook" != *"README.md" ]] && [ -f "$hook" ]; then
    hook_name=$(basename "$hook")
    echo "  - $hook_name"
  fi
done
echo ""
echo "These hooks prevent direct commits/pushes to protected branches."
echo "To override when needed, use:"
echo "  SKIP_HOOKS=1 git commit -m \"message\""
echo "  SKIP_HOOKS=1 git push"
echo ""
