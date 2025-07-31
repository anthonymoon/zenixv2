#!/usr/bin/env bash
set -euo pipefail

echo "📝 Committing formatting changes to all repositories..."

# Function to commit and push if there are changes
commit_and_push() {
    local repo_path="$1"
    local repo_name=$(basename "$repo_path")
    
    echo ""
    echo "🔍 Checking $repo_name..."
    
    cd "$repo_path"
    
    if git diff --quiet && git diff --cached --quiet; then
        echo "  ✅ No changes to commit"
    else
        echo "  📦 Committing formatting changes..."
        git add -A
        git commit -m "chore: format all Nix files with nixpkgs-fmt

- Applied nixpkgs-fmt to all .nix files for consistent formatting
- Ensures clean and standardized Nix code across the repository
- No functional changes, only formatting improvements"
        
        echo "  🚀 Pushing to GitHub..."
        git push origin main || git push origin master || echo "  ⚠️  Push failed or no remote"
        echo "  ✅ Done"
    fi
}

# Commit changes in all repos
REPOS=(
    "/Users/amoon/nix/nix/nixos-claude"
    "/Users/amoon/nix/nix/nixos-fun"
    "/Users/amoon/nix/nix/nixos-unified"
    "/Users/amoon/nix/nix/nixos-zfs"
    "/Users/amoon/nix/nix/nixos-zfsroot"
    "/Users/amoon/nix/nixos-zfs-installer"
    "/Users/amoon/nix/nixos-zfs-minimal"
)

for repo in "${REPOS[@]}"; do
    if [ -d "$repo" ]; then
        commit_and_push "$repo"
    fi
done

echo ""
echo "✅ All formatting changes have been committed and pushed!"