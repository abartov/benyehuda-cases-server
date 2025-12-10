#!/bin/bash
# Install git hooks via Overcommit to prevent accidental pushes to protected branches
#
# This script installs hooks using Overcommit, which manages all git hooks for this repository.
# This ensures that both protected branch checks AND existing code quality checks (TrailingWhitespace,
# RuboCop, etc.) all work together seamlessly.

echo "Installing git hooks via Overcommit..."
echo ""

# Check if we're in a git repository
if [ ! -d ".git" ]; then
  echo "❌ Error: Not in a git repository root directory"
  exit 1
fi

# Check if .overcommit.yml exists
if [ ! -f ".overcommit.yml" ]; then
  echo "❌ Error: .overcommit.yml not found"
  echo "   This repository requires Overcommit for hook management"
  exit 1
fi

# Check if overcommit is available
if ! command -v overcommit &> /dev/null; then
  # Try via bundler first
  if command -v bundle &> /dev/null && bundle show overcommit &> /dev/null; then
    echo "Using Overcommit via Bundler..."
    OVERCOMMIT_CMD="bundle exec overcommit"
  else
    echo "❌ Error: Overcommit is not installed"
    echo ""
    echo "Please install Overcommit first:"
    echo "  Option 1 (Recommended): bundle install"
    echo "  Option 2: gem install overcommit"
    echo ""
    exit 1
  fi
else
  OVERCOMMIT_CMD="overcommit"
fi

# Install Overcommit hooks
echo "Running: $OVERCOMMIT_CMD --install"
$OVERCOMMIT_CMD --install

if [ $? -eq 0 ]; then
  echo ""
  echo "✓ Git hooks installed successfully via Overcommit!"
  echo ""
  echo "These hooks will:"
  echo "  • Prevent commits to master, main, and other protected branches"
  echo "  • Prevent pushes to protected branches"
  echo "  • Check for trailing whitespace"
  echo "  • Run other configured code quality checks"
  echo "  • Remind you to follow the proper PR workflow"
  echo ""
  echo "To bypass hooks in emergencies (use with caution):"
  echo "  OVERCOMMIT_DISABLE=1 git commit"
  echo "  git push --no-verify"
  echo ""
else
  echo ""
  echo "❌ Error: Failed to install Overcommit hooks"
  exit 1
fi
