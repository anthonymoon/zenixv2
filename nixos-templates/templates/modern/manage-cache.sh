#!/usr/bin/env bash
# Management script for local Nix cache

set -euo pipefail

CACHE_URL="http://localhost:5000"

show_help() {
    cat << EOF
Local Nix Cache Management Tool

Usage: $0 [command] [options]

Commands:
    status          Show cache service status and statistics
    start           Start the cache service
    stop            Stop the cache service
    restart         Restart the cache service
    logs            Show cache service logs
    test            Test cache connectivity
    populate        Populate cache with common packages
    upload PATH     Upload a specific store path to cache
    info            Show cache information
    size            Show cache disk usage

Examples:
    $0 status
    $0 upload /nix/store/abc123-package
    $0 populate

EOF
}

check_service() {
    if ! systemctl --user is-active nix-serve.service &> /dev/null; then
        echo "❌ nix-serve is not running. Start it with: $0 start"
        return 1
    fi
    return 0
}

case "${1:-help}" in
    status)
        echo "=== Nix Cache Service Status ==="
        systemctl --user status nix-serve.service
        echo ""
        if check_service; then
            echo "=== Cache Information ==="
            curl -s $CACHE_URL/nix-cache-info || echo "Failed to get cache info"
        fi
        ;;
    
    start)
        echo "Starting nix-serve..."
        systemctl --user start nix-serve.service
        sleep 2
        $0 status
        ;;
    
    stop)
        echo "Stopping nix-serve..."
        systemctl --user stop nix-serve.service
        ;;
    
    restart)
        echo "Restarting nix-serve..."
        systemctl --user restart nix-serve.service
        sleep 2
        $0 status
        ;;
    
    logs)
        journalctl --user -u nix-serve.service -f
        ;;
    
    test)
        echo "Testing cache connectivity..."
        if curl -s -o /dev/null -w "%{http_code}" $CACHE_URL/nix-cache-info | grep -q "200"; then
            echo "✅ Cache is accessible at $CACHE_URL"
            curl -s $CACHE_URL/nix-cache-info
        else
            echo "❌ Cache is not accessible"
            exit 1
        fi
        ;;
    
    populate)
        if ! check_service; then exit 1; fi
        
        echo "Populating cache with common packages..."
        echo "This may take a while..."
        
        # Common development tools
        PACKAGES=(
            "nixpkgs.git"
            "nixpkgs.gnumake"
            "nixpkgs.gcc"
            "nixpkgs.nodejs"
            "nixpkgs.python3"
            "nixpkgs.ripgrep"
            "nixpkgs.fd"
            "nixpkgs.bat"
            "nixpkgs.htop"
            "nixpkgs.tmux"
        )
        
        for pkg in "${PACKAGES[@]}"; do
            echo "Building and caching $pkg..."
            nix-build '<nixpkgs>' -A "${pkg#nixpkgs.}" --no-out-link || true
        done
        
        echo "✅ Cache population complete!"
        ;;
    
    upload)
        if ! check_service; then exit 1; fi
        
        if [[ -z "${2:-}" ]]; then
            echo "Error: Please specify a store path to upload"
            echo "Usage: $0 upload /nix/store/..."
            exit 1
        fi
        
        echo "Uploading $2 to cache..."
        NIX_SECRET_KEY_FILE=/var/keys/cache-priv-key.pem nix copy --to "$CACHE_URL" "$2"
        echo "✅ Upload complete!"
        ;;
    
    info)
        if ! check_service; then exit 1; fi
        
        echo "=== Local Nix Cache Information ==="
        curl -s $CACHE_URL/nix-cache-info
        echo ""
        echo "=== Nix Configuration ==="
        nix show-config | grep -E "(substituters|trusted-public-keys|post-build-hook)" || true
        ;;
    
    size)
        echo "=== Nix Store Size ==="
        du -sh /nix/store 2>/dev/null || echo "Unable to determine store size (may need sudo)"
        echo ""
        echo "=== Store Path Count ==="
        find /nix/store -maxdepth 1 -type d 2>/dev/null | wc -l || echo "Unable to count paths"
        ;;
    
    help|--help|-h)
        show_help
        ;;
    
    *)
        echo "Unknown command: $1"
        show_help
        exit 1
        ;;
esac