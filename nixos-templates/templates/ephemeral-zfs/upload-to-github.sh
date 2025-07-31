#!/usr/bin/env bash
# Script to upload repository to GitHub

set -e

GITHUB_USER="anthonymoon"
GITHUB_REPO="zfs"
GITHUB_URL="https://github.com/${GITHUB_USER}/${GITHUB_REPO}"

echo "=== Preparing to upload to GitHub ==="
echo "Repository: $GITHUB_URL"
echo

# Check if git is initialized
if [ ! -d .git ]; then
    echo "Initializing git repository..."
    git init
    git branch -M main
fi

# Check current remote
CURRENT_REMOTE=$(git remote get-url origin 2>/dev/null || echo "none")
if [ "$CURRENT_REMOTE" != "none" ] && [ "$CURRENT_REMOTE" != "${GITHUB_URL}.git" ]; then
    echo "Warning: Current remote is: $CURRENT_REMOTE"
    read -r -p "Change to $GITHUB_URL? (y/n): " change_remote
    if [ "$change_remote" = "y" ]; then
        git remote remove origin
        git remote add origin "${GITHUB_URL}.git"
    fi
elif [ "$CURRENT_REMOTE" = "none" ]; then
    echo "Adding GitHub remote..."
    git remote add origin "${GITHUB_URL}.git"
fi

# Clean up test files
echo "Cleaning up test files..."
rm -rf test-build/ ./*-test/ test-output.log configuration-test.nix flake-test.nix hardware-test/ || true

# Update README with correct GitHub URLs
echo "Updating README with correct GitHub URLs..."
sed -i "s|YOUR_USER/YOUR_REPO|${GITHUB_USER}/${GITHUB_REPO}|g" README.md
sed -i "s|YOUR_USER/YOUR_REPO|${GITHUB_USER}/${GITHUB_REPO}|g" REMOTE_INSTALL.md
sed -i "s|YourGitHubUser/YourRepoName|${GITHUB_USER}/${GITHUB_REPO}|g" install-from-url.sh

# Add all files
echo "Adding files to git..."
git add -A

# Show status
echo
echo "Git status:"
git status --short

# Commit
echo
echo "Creating commit..."
git commit -m "NixOS ephemeral root ZFS configuration with Cachix optimization

Features:
- Ephemeral root filesystem that resets on boot
- ZFS with snapshots and persistent data paths
- Remote installation support (SSH and direct URL)
- Multi-host flake configuration
- Cachix binary caches for 50-80% faster installation
- Comprehensive test suite
- Hardware optimized for B550-F/Ryzen 5600X/Radeon 7800XT

Installation methods:
- Direct from GitHub URL
- Remote via SSH
- Local installation
- Optimized installer with Cachix

Includes full documentation and test coverage." || echo "No changes to commit"

echo
echo "=== Ready to push to GitHub ==="
echo
echo "Before pushing, make sure:"
echo "1. You have created the repository at: $GITHUB_URL"
echo "2. The repository is empty (no README, license, or .gitignore)"
echo "3. You are logged in to GitHub (use 'gh auth login' if needed)"
echo
echo "To push to GitHub, run:"
echo "  git push -u origin main"
echo
echo "If you haven't created the repo yet, you can use GitHub CLI:"
echo "  gh repo create ${GITHUB_USER}/${GITHUB_REPO} --public --description 'NixOS ephemeral root ZFS configuration'"
echo
echo "After pushing, the direct installation URL will be:"
echo "  bash <(curl -sL https://raw.githubusercontent.com/${GITHUB_USER}/${GITHUB_REPO}/main/install-from-url.sh) hostname disk"