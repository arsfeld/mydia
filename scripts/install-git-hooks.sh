#!/usr/bin/env bash

# Install git hooks from .githooks directory
# This allows version-controlled git hooks

set -e

HOOKS_DIR=".githooks"
GIT_HOOKS_DIR=".git/hooks"

echo "Installing git hooks..."

# Check if .githooks directory exists
if [ ! -d "$HOOKS_DIR" ]; then
  echo "Error: $HOOKS_DIR directory not found"
  exit 1
fi

# Create symlinks for each hook in .githooks
for hook in "$HOOKS_DIR"/*; do
  if [ -f "$hook" ]; then
    hook_name=$(basename "$hook")
    target="$GIT_HOOKS_DIR/$hook_name"

    # Remove existing hook or symlink
    if [ -e "$target" ] || [ -L "$target" ]; then
      rm "$target"
    fi

    # Create symlink (use relative path)
    ln -s "../../$HOOKS_DIR/$hook_name" "$target"

    # Make sure the hook is executable
    chmod +x "$hook"

    echo "  ✅ Installed $hook_name"
  fi
done

echo ""
echo "Git hooks installed successfully!"
echo "Hooks will now run automatically on git operations."
