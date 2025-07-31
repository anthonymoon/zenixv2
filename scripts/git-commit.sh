#!/usr/bin/env bash
# Git commit wrapper that ensures we're in the dev shell

set -e

# Check if we're already in a dev shell
if [ -n "$IN_NIX_SHELL" ]; then
    # We're in the shell, just run git commit
    exec git commit "$@"
else
    # We're not in the shell, use nix develop to run the command
    echo "Running git commit in nix dev shell..."
    exec nix develop -c git commit "$@"
fi