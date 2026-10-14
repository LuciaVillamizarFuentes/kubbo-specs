#!/usr/bin/env bash
# Elimina los worktrees de una feature cuando sus PRs ya se mergearon.
#
# Uso: ./scripts/finish-feature.sh <NNN-feature-name>
set -euo pipefail

WORKSPACE="${KUBBO_WORKSPACE:-$HOME/workspace}"
FEATURE="${1:?Uso: ./scripts/finish-feature.sh <NNN-feature-name>}"
TARGET="$WORKSPACE/features/$FEATURE"

for repo in kubbo-specs kubbo-api kubbo-web; do
  dest="$TARGET/$repo"
  [ -d "$dest" ] || continue
  if [ -n "$(git -C "$dest" status --porcelain)" ]; then
    echo "✗ $repo tiene cambios sin commit en $dest. Haz commit o descártalos antes de cerrar." >&2
    exit 1
  fi
  git -C "$WORKSPACE/$repo" worktree remove "$dest"
  if git -C "$WORKSPACE/$repo" branch --merged main | grep -qx "  $FEATURE"; then
    git -C "$WORKSPACE/$repo" branch -d "$FEATURE"
    echo "✓ $repo: worktree y rama eliminados"
  else
    echo "• $repo: worktree eliminado; la rama $FEATURE se conserva porque aún no está mergeada en main local (haz git pull en main)"
  fi
done

rmdir "$TARGET" 2>/dev/null || true
echo "Feature $FEATURE cerrada."
