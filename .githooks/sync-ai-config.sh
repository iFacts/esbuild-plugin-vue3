#!/bin/sh
# Symlinks always-on standards and path-scoped rules from .ai-config/claude/ into .claude/
REPO_ROOT="$(git rev-parse --show-toplevel)"
SOURCE="$REPO_ROOT/.ai-config/claude"
TARGET="$REPO_ROOT/.claude"

if [ ! -d "$SOURCE" ]; then
  echo "[sync-ai-config] No .ai-config/claude/ found — skipping."
  exit 0
fi

mkdir -p "$TARGET/rules"

# Sync rules
if [ -d "$SOURCE/rules" ]; then
  for f in "$SOURCE/rules"/*.md; do
    [ -f "$f" ] || continue
    name="$(basename "$f")"
    dest="$TARGET/rules/$name"
    if [ -e "$dest" ] && [ ! -L "$dest" ]; then continue; fi
    ln -sf "$f" "$dest"
  done
fi

echo "[sync-ai-config] Rules synced into .claude/"
