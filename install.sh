#!/bin/bash
# Install Conductor for OpenCode, Claude, Codex, Gemini CLI, Antigravity
# Usage: ./install.sh

set -e
ROOT="$(cd "$(dirname "$0")" && pwd)"

# Guard: do not run installer from the repository root
if [ "$(pwd)" = "$ROOT" ]; then
  echo "Installer must not be run from the Conductor source tree (current directory: $(pwd))."
  exit 1
fi

echo "Installing Conductor..."

install_skill_flavor() {
  local dir="$1"
  rm -rf "$dir"
  mkdir -p "$dir"
  cp "$ROOT/skill/SKILL.md" "$dir/"
  echo "  $dir"
}

install_packaged_surface() {
  local dir="$1"
  rm -rf "$dir"
  mkdir -p "$dir"
  cp -R "$ROOT/.opencode" "$dir"
  cp -R "$ROOT/conductor" "$dir"
  echo "  $dir"
}

install_gemini_flavor() {
  local dir="$1"
  rm -rf "$dir"
  mkdir -p "$dir"
  cp "$ROOT/skill/SKILL.md" "$dir/SKILL.md"
  cp "$ROOT/gemini-extension.json" "$dir/"
  cp -R "$ROOT/.opencode" "$dir"
  cp -R "$ROOT/conductor" "$dir"
  echo "  $dir (Gemini CLI)"
}

install_skill_flavor "$HOME/.opencode/skill/conductor"
install_packaged_surface "$HOME/.opencode/conductor"

for dir in "$HOME/.claude/skills/conductor" "$HOME/.codex/skills/conductor"; do
  install_skill_flavor "$dir"
done

install_gemini_flavor "$HOME/.gemini/extensions/conductor"

dir="$HOME/.gemini/antigravity/skills/conductor"
install_skill_flavor "$dir"

echo "Done. Restart your AI shell."
