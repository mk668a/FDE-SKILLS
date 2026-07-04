#!/usr/bin/env bash
# install.sh — install FDE-SKILLS without the Claude Code marketplace.
#
# It's plain `cp` under the hood (plus a one-line `sed` to namespace each skill):
# copies each skill dir into your personal skills dir as fde-* (so the generic
# names init/draft/promote/recall can't collide with built-ins or your own
# skills). The spine templates ride inside skills/init/, and /fde-init reads
# them from ${CLAUDE_SKILL_DIR}, so there's no second install location.
#
# usage:
#   ./install.sh        install or update
#   ./install.sh -u     uninstall (remove everything this script installed)
set -euo pipefail

src=$(cd "$(dirname "$0")" && pwd)
skills="$HOME/.claude/skills"

if [ "${1:-}" = "-u" ] || [ "${1:-}" = "--uninstall" ]; then
  for d in "$src"/skills/*/; do rm -rf "$skills/fde-$(basename "$d")"; done
  echo "Removed FDE-SKILLS from $skills"
  exit 0
fi

# Each skill -> fde-<name> (whole dir, so init's templates/ come along).
# Normalize every /fde: cross-ref to the flat /fde- form personal skills use
# — across SKILL.md AND the bundled spine (scripts, schemas, config) that
# /fde-init later copies into the workspace — then rewrite the skill's own name.
mkdir -p "$skills"
n=0
for d in "$src"/skills/*/; do
  name=$(basename "$d")
  dest="$skills/fde-$name"
  rm -rf "$dest"
  cp -R "$d" "$dest"
  find "$dest" -type f \( -name '*.md' -o -name '*.sh' -o -name '*.yml' \) -print0 |
    while IFS= read -r -d '' f; do
      sed 's#/fde:#/fde-#g' "$f" > "$f.tmp" && mv "$f.tmp" "$f"
    done
  sed "s#^name: ${name}\$#name: fde-${name}#" "$dest/SKILL.md" > "$dest/SKILL.md.tmp" &&
    mv "$dest/SKILL.md.tmp" "$dest/SKILL.md"
  chmod +x "$dest"/templates/bin/*.sh 2>/dev/null || true
  n=$((n + 1))
done

echo "Installed $n fde-* skills -> $skills"
echo
echo "Next: in any workspace just say \"set up fde here\" (or run /fde-init),"
echo "then \"new engagement with <Client>\" (also /fde-init)."
