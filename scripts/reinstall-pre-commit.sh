#\!/usr/bin/env bash
set -euo pipefail

echo "🔧 Reinstalling pre-commit hooks for all repositories..."

# Function to reinstall pre-commit hooks
reinstall_hooks() {
    local repo_path="$1"
    local repo_name=$(basename "$repo_path")
    
    echo ""
    echo "📦 Processing $repo_name..."
    
    cd "$repo_path"
    
    # Check if .pre-commit-config.yaml exists
    if [ -f ".pre-commit-config.yaml" ]; then
        echo "  🔍 Found .pre-commit-config.yaml"
        
        # Check if git repo
        if [ -d ".git" ]; then
            # Install pre-commit hooks
            if command -v pre-commit >/dev/null 2>&1; then
                echo "  📥 Installing pre-commit hooks..."
                pre-commit install --allow-missing-config || echo "  ⚠️  Failed to install hooks"
                
                # Run pre-commit to ensure everything is set up
                echo "  🧪 Testing pre-commit..."
                pre-commit run --all-files || echo "  ⚠️  Pre-commit run had issues (this is normal for initial setup)"
            else
                echo "  ⚠️  pre-commit not found in PATH, trying with nix-shell..."
                nix-shell -p pre-commit --run "pre-commit install --allow-missing-config" || echo "  ⚠️  Failed with nix-shell"
            fi
        else
            echo "  ⚠️  Not a git repository"
        fi
    else
        echo "  ℹ️  No .pre-commit-config.yaml found"
    fi
}

# List of all repositories
REPOS=(
    "/Users/amoon/nix/nix/nixos-claude"
    "/Users/amoon/nix/nix/nixos-fun"
    "/Users/amoon/nix/nix/nixos-unified"
    "/Users/amoon/nix/nix/nixos-zfs"
    "/Users/amoon/nix/nix/nixos-zfsroot"
    "/Users/amoon/nix/nixos-zfs-installer"
    "/Users/amoon/nix/nixos-zfs-minimal"
)

# Process each repository
for repo in "${REPOS[@]}"; do
    if [ -d "$repo" ]; then
        reinstall_hooks "$repo"
    else
        echo "⚠️  Repository not found: $repo"
    fi
done

echo ""
echo "✅ Pre-commit hook reinstallation complete\!"
