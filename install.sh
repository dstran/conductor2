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

install_opencode_surface() {
  # OpenCode discovers global skills under ~/.config/opencode/skills/<name>/SKILL.md
  # and global commands under ~/.config/opencode/command/**/*.md. Command names are
  # derived from the path after the "command/" prefix, so nesting under conductor/
  # exposes them as /conductor/<name>.
  local config="$HOME/.config/opencode"
  local skill_dir="$config/skills/conductor"
  local command_dir="$config/command/conductor"
  local assets_dir="$command_dir/assets/code_styleguides"

  rm -rf "$skill_dir" "$command_dir"
  mkdir -p "$skill_dir" "$command_dir" "$assets_dir"
  cp "$ROOT/skill/SKILL.md" "$skill_dir/SKILL.md"
  cp "$ROOT"/.opencode/command/*.md "$command_dir/"
  cp "$ROOT"/conductor/assets/code_styleguides/*.md "$assets_dir/"
  echo "  $skill_dir"
  echo "  $command_dir (/conductor/*)"
  echo "  $assets_dir (style guides)"
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

install_opencode_surface

for dir in "$HOME/.claude/skills/conductor" "$HOME/.codex/skills/conductor"; do
  install_skill_flavor "$dir"
done

install_gemini_flavor "$HOME/.gemini/extensions/conductor"

dir="$HOME/.gemini/antigravity/skills/conductor"
install_skill_flavor "$dir"

echo "Done. Restart your AI shell."
