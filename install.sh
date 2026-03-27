#!/usr/bin/env bash
# my-ecc installer — Copy ECC commands and templates to target project.
#
# Usage:
#   ./install.sh <target-project-path>
#   ./install.sh                        # defaults to current directory
#   ./install.sh -f <target>            # force overwrite existing files

set -euo pipefail

FORCE=false
if [ "${1:-}" = "-f" ]; then
  FORCE=true
  shift
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TARGET="${1:-.}"

if [ ! -d "$TARGET" ]; then
  echo "Error: Target directory does not exist: $TARGET"
  exit 1
fi

TARGET="$(cd "$TARGET" && pwd)"

echo "my-ecc installer"
echo "================"
echo ""
echo "Source:  $SCRIPT_DIR"
echo "Target:  $TARGET"
echo ""

# Create directories
mkdir -p "$TARGET/.claude/commands"
mkdir -p "$TARGET/docs"
mkdir -p "$TARGET/docs/ecc-templates"

copy_file() {
  local src="$1" dst="$2" label="$3"
  if [ ! -f "$src" ]; then
    echo "  [WARN] $label — source not found"
    return
  fi
  if [ -f "$dst" ] && [ "$FORCE" = false ]; then
    echo "  [SKIP] $label (exists — use -f to overwrite)"
  else
    cp "$src" "$dst"
    echo "  [COPY] $label"
  fi
}

# Copy commands
echo "Commands:"
for cmd in ecc-init ecc-bootstrap ecc-configure ecc-evolve ecc-setup; do
  copy_file "$SCRIPT_DIR/.claude/commands/${cmd}.md" \
            "$TARGET/.claude/commands/${cmd}.md" \
            "$cmd.md"
done

# Copy shared spec
echo ""
echo "Docs:"
copy_file "$SCRIPT_DIR/docs/ecc-shared-spec.md" \
          "$TARGET/docs/ecc-shared-spec.md" \
          "ecc-shared-spec.md"

# Copy templates
echo ""
echo "Templates:"
for tmpl in settings.json CLAUDE.md.template gitignore.append; do
  copy_file "$SCRIPT_DIR/templates/$tmpl" \
            "$TARGET/docs/ecc-templates/$tmpl" \
            "templates/$tmpl"
done

echo ""
echo "Done!"
echo ""
echo "Next steps:"
echo "  cd $TARGET"
echo "  claude"
echo "  /ecc-init"
