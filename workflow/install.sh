#!/bin/bash
# install.sh — Copy rossflow workflow into a target project.
# Usage: bash install.sh /path/to/target-project
#        bash install.sh .
set -euo pipefail

ROSSFLOW_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ─── Argument validation ───────────────────────────────────────────────────────

if [[ $# -lt 1 ]]; then
  echo "Usage: bash install.sh /path/to/target-project"
  echo "       bash install.sh ."
  exit 1
fi

TARGET="$(cd "$1" 2>/dev/null && pwd)" || {
  echo "Error: target path does not exist: $1"
  exit 1
}

# ─── Source validation ─────────────────────────────────────────────────────────

MISSING=0
for SRC_DIR in skills templates patterns config-templates docs-templates; do
  if [[ ! -d "$ROSSFLOW_DIR/$SRC_DIR" ]]; then
    echo "Error: rossflow source directory missing: $ROSSFLOW_DIR/$SRC_DIR"
    MISSING=1
  fi
done

if [[ ! -f "$ROSSFLOW_DIR/workflow-instructions.md" ]]; then
  echo "Error: rossflow source file missing: $ROSSFLOW_DIR/workflow-instructions.md"
  MISSING=1
fi

if [[ $MISSING -ne 0 ]]; then
  exit 1
fi

# ─── Version ───────────────────────────────────────────────────────────────────

NEW_VERSION="unknown"
if command -v git &>/dev/null; then
  NEW_VERSION="$(git -C "$ROSSFLOW_DIR" rev-parse --short HEAD 2>/dev/null || echo "unknown")"
fi

# ─── Re-run check ──────────────────────────────────────────────────────────────

VERSION_FILE="$TARGET/.claude/rossflow/version.txt"
if [[ -f "$VERSION_FILE" ]]; then
  EXISTING_VERSION="$(cat "$VERSION_FILE")"
  printf "rossflow already installed (version: %s). Reinstall with %s? (y/N) " \
    "$EXISTING_VERSION" "$NEW_VERSION"
  read -r ANSWER || ANSWER="N"
  case "${ANSWER:-N}" in
    [yY]) ;;
    *) echo "Aborted."; exit 0 ;;
  esac
fi

# ─── Error trap ────────────────────────────────────────────────────────────────

trap 'echo "" >&2; echo "Error: install.sh failed at line $LINENO" >&2; exit 1' ERR

# ─── Create base directories ───────────────────────────────────────────────────

mkdir -p "$TARGET/.claude/rossflow"
mkdir -p "$TARGET/.claude/skills"

# ─── Skills — skip existing, never overwrite ───────────────────────────────────

SKILLS_INSTALLED=0
SKILLS_SKIPPED=0

for SKILL_SRC in "$ROSSFLOW_DIR/skills"/*/; do
  [[ -d "$SKILL_SRC" ]] || continue
  SKILL_NAME="$(basename "$SKILL_SRC")"
  SKILL_DST="$TARGET/.claude/skills/$SKILL_NAME"

  if [[ -d "$SKILL_DST" ]]; then
    echo "  → Skipped .claude/skills/$SKILL_NAME/ (already exists)"
    SKILLS_SKIPPED=$((SKILLS_SKIPPED + 1))
    continue
  fi

  mkdir -p "$SKILL_DST"
  echo "  ✓ Created .claude/skills/$SKILL_NAME/"

  for FILE in "$SKILL_SRC"*; do
    [[ -f "$FILE" ]] || continue
    cp "$FILE" "$SKILL_DST/"
    echo "  ✓ Copied $SKILL_NAME/$(basename "$FILE")"
  done

  SKILLS_INSTALLED=$((SKILLS_INSTALLED + 1))
done

echo "  → $SKILLS_INSTALLED skills installed, $SKILLS_SKIPPED skipped"

# ─── Rossflow asset directories ────────────────────────────────────────────────

for ASSET_DIR in templates patterns config-templates docs-templates; do
  ASSET_DST="$TARGET/.claude/rossflow/$ASSET_DIR"
  mkdir -p "$ASSET_DST"
  cp -rp "$ROSSFLOW_DIR/$ASSET_DIR/." "$ASSET_DST/"
  echo "  ✓ Copied rossflow $ASSET_DIR"
done

# ─── workflow-instructions.md ──────────────────────────────────────────────────

cp "$ROSSFLOW_DIR/workflow-instructions.md" "$TARGET/.claude/workflow-instructions.md"
echo "  ✓ Wrote workflow-instructions.md"

# ─── version.txt ───────────────────────────────────────────────────────────────

printf "%s\n" "$NEW_VERSION" > "$TARGET/.claude/rossflow/version.txt"
echo "  ✓ Wrote version.txt ($NEW_VERSION)"

# ─── Done ──────────────────────────────────────────────────────────────────────

echo ""
echo "rossflow installed into $TARGET"
echo ""
echo "Next: open Claude Code in your project and run /workflow-init"
