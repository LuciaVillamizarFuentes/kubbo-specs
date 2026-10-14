#!/usr/bin/env bash
# Crea un worktree por repo para una feature, todos con la misma rama.
#
# Uso:   ./scripts/new-feature.sh <NNN-feature-name> [api] [web]
# Ejemplo: ./scripts/new-feature.sh 000-platform-foundation api
#
# Resultado:
#   ~/workspace/features/<NNN-feature-name>/kubbo-specs   (siempre)
#   ~/workspace/features/<NNN-feature-name>/kubbo-api     (si pasas "api")
#   ~/workspace/features/<NNN-feature-name>/kubbo-web     (si pasas "web")
set -euo pipefail

WORKSPACE="${KUBBO_WORKSPACE:-$HOME/workspace}"
FEATURE="${1:-}"
shift || true

if [[ ! "$FEATURE" =~ ^[0-9]{3}-[a-z0-9]+(-[a-z0-9]+)*$ ]]; then
  echo "Error: el nombre debe tener el formato NNN-kebab-case (ej. 001-multitenant-identity)." >&2
  exit 1
fi

REPOS=("kubbo-specs")
for arg in "$@"; do
  case "$arg" in
    api) REPOS+=("kubbo-api") ;;
    web) REPOS+=("kubbo-web") ;;
    *) echo "Error: argumento desconocido '$arg' (usa api y/o web)." >&2; exit 1 ;;
  esac
done

TARGET="$WORKSPACE/features/$FEATURE"
mkdir -p "$TARGET"

for repo in "${REPOS[@]}"; do
  src="$WORKSPACE/$repo"
  dest="$TARGET/$repo"
  if [ -d "$dest" ]; then
    echo "• $repo: el worktree ya existe en $dest"
    continue
  fi
  if ! git -C "$src" rev-parse --verify main >/dev/null 2>&1; then
    echo "Error: $repo no tiene la rama main con al menos un commit." >&2
    exit 1
  fi
  base="main"
  if git -C "$src" remote get-url origin >/dev/null 2>&1; then
    git -C "$src" fetch --quiet origin main && base="origin/main"
  fi
  if git -C "$src" rev-parse --verify "$FEATURE" >/dev/null 2>&1; then
    git -C "$src" worktree add "$dest" "$FEATURE"
  else
    git -C "$src" worktree add -b "$FEATURE" "$dest" "$base"
  fi
  echo "✓ $repo → $dest (rama $FEATURE)"
done

ADD_DIRS=""
for repo in "${REPOS[@]:1}"; do ADD_DIRS+=" ../$repo"; done

echo
echo "Listo. Para trabajar en la feature abre Claude Code así:"
echo
echo "  cd \"$TARGET/kubbo-specs\" && CLAUDE_CODE_ADDITIONAL_DIRECTORIES_CLAUDE_MD=1 claude${ADD_DIRS:+ --add-dir$ADD_DIRS}"
echo
echo "Si la feature necesita otro repo después, vuelve a correr este script agregándolo."
