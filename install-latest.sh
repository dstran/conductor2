#!/bin/bash
# Fetch the latest Conductor from GitHub and install it.
#
# Usage (always latest):
#   curl -fsSL https://raw.githubusercontent.com/dstran/conductor2/main/install-latest.sh | bash
# or, from a local copy:
#   bash install-latest.sh
#
# Overridable via environment variables:
#   CONDUCTOR_REPO  git URL to clone   (default: https://github.com/dstran/conductor2.git)
#   CONDUCTOR_REF   branch/tag/ref     (default: main)
#   XDG_CACHE_HOME  cache base dir     (default: $HOME/.cache)

set -e

REPO="${CONDUCTOR_REPO:-https://github.com/dstran/conductor2.git}"
REF="${CONDUCTOR_REF:-main}"
CACHE_BASE="${XDG_CACHE_HOME:-$HOME/.cache}"
CLONE_DIR="$CACHE_BASE/conductor2"

if ! command -v git >/dev/null 2>&1; then
  echo "git is required but was not found on PATH." >&2
  exit 1
fi

echo "Fetching Conductor ($REF) from $REPO ..."

if [ -d "$CLONE_DIR/.git" ]; then
  git -C "$CLONE_DIR" remote set-url origin "$REPO"
  git -C "$CLONE_DIR" fetch --quiet --tags origin
  git -C "$CLONE_DIR" checkout --quiet "$REF"
  git -C "$CLONE_DIR" reset --hard --quiet "origin/$REF"
else
  rm -rf "$CLONE_DIR"
  mkdir -p "$CACHE_BASE"
  git clone --quiet "$REPO" "$CLONE_DIR"
  git -C "$CLONE_DIR" checkout --quiet "$REF"
fi

SHA="$(git -C "$CLONE_DIR" rev-parse --short HEAD)"
echo "Synced to $REF ($SHA)."

# install.sh refuses to run from the repo root, so invoke it from $HOME.
( cd "$HOME" && bash "$CLONE_DIR/install.sh" )

echo "Installed Conductor from $REPO@$REF ($SHA)."
