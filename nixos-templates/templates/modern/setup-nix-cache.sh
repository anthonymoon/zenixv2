#!/usr/bin/env bash
# Setup script for local Nix cache on non-NixOS systems

set -euo pipefail

echo "Setting up local Nix cache for CachyOS..."

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   echo "Please run this script as a regular user (not root)"
   exit 1
fi

# Check if nix is installed
if ! command -v nix &> /dev/null; then
    echo "Nix is not installed. Please install Nix first."
    echo "Visit: https://nixos.org/download.html"
    exit 1
fi

# Ensure keys exist
if [[ ! -f /var/keys/cache-priv-key.pem ]]; then
    echo "Cache keys not found. Generating..."
    sudo /home/amoon/nixos-cachydotlocal/scripts/generate-cache-key.sh
fi

# Read the public key
PUBLIC_KEY=$(sudo cat /var/keys/cache-pub-key.pem)

# Create nix configuration directory if it doesn't exist
mkdir -p ~/.config/nix

# Create a local nix configuration
cat > ~/.config/nix/nix.conf << EOF
# Enable experimental features
experimental-features = nix-command flakes

# Local cache configuration
substituters = http://localhost:5000 https://cache.nixos.org https://nix-community.cachix.org
trusted-substituters = http://localhost:5000 https://cache.nixos.org https://nix-community.cachix.org
trusted-public-keys = cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY= nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs= ${PUBLIC_KEY}

# Performance optimizations
max-jobs = auto
cores = 0
keep-outputs = true
keep-derivations = true
builders-use-substitutes = true
connect-timeout = 5
download-attempts = 3

# Caching optimizations
narinfo-cache-positive-ttl = 86400
narinfo-cache-negative-ttl = 3600
EOF

echo "Nix configuration created at ~/.config/nix/nix.conf"

# Create systemd user service for nix-serve
mkdir -p ~/.config/systemd/user

cat > ~/.config/systemd/user/nix-serve.service << 'EOF'
[Unit]
Description=Local Nix binary cache server
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/env bash -c 'exec $(which nix-serve) -p 5000 --secret-key-file /var/keys/cache-priv-key.pem'
Restart=always
RestartSec=5
Environment="PATH=/run/current-system/sw/bin:/nix/var/nix/profiles/default/bin:/home/%u/.nix-profile/bin:/usr/local/bin:/usr/bin:/bin"

[Install]
WantedBy=default.target
EOF

echo "Created systemd user service for nix-serve"

# Install nix-serve if not already installed
if ! command -v nix-serve &> /dev/null; then
    echo "Installing nix-serve..."
    nix-env -iA nixpkgs.nix-serve
fi

# Create a post-build hook script
mkdir -p ~/.config/nix/hooks
cat > ~/.config/nix/hooks/upload-to-cache.sh << 'EOF'
#!/usr/bin/env bash
set -euf -o pipefail

# Only upload if nix-serve is running
if curl -s -o /dev/null -w "%{http_code}" http://localhost:5000/nix-cache-info | grep -q "200"; then
    export NIX_SECRET_KEY_FILE=/var/keys/cache-priv-key.pem
    echo "Uploading $OUT_PATHS to local cache..." >&2
    exec nix copy --to 'http://localhost:5000' $OUT_PATHS
fi
EOF

chmod +x ~/.config/nix/hooks/upload-to-cache.sh

# Add post-build hook to nix.conf
if ! grep -q "post-build-hook" ~/.config/nix/nix.conf; then
    echo "" >> ~/.config/nix/nix.conf
    echo "# Post-build hook to upload to local cache" >> ~/.config/nix/nix.conf
    echo "post-build-hook = $HOME/.config/nix/hooks/upload-to-cache.sh" >> ~/.config/nix/nix.conf
fi

# Enable and start the nix-serve service
echo "Starting nix-serve..."
systemctl --user daemon-reload
systemctl --user enable nix-serve.service
systemctl --user start nix-serve.service

# Wait for service to start
sleep 2

# Check if service is running
if systemctl --user is-active nix-serve.service &> /dev/null; then
    echo "✅ nix-serve is running!"
else
    echo "❌ Failed to start nix-serve. Check logs with: journalctl --user -u nix-serve"
    exit 1
fi

# Test the cache
echo "Testing local cache..."
if curl -s http://localhost:5000/nix-cache-info | grep -q "StoreDir"; then
    echo "✅ Local cache is accessible!"
    curl -s http://localhost:5000/nix-cache-info
else
    echo "❌ Failed to access local cache"
    exit 1
fi

echo ""
echo "🎉 Local Nix cache setup complete!"
echo ""
echo "Your local cache is now running on http://localhost:5000"
echo "Nix will automatically use it for all operations."
echo ""
echo "To manually upload existing store paths to the cache:"
echo "  nix copy --to 'http://localhost:5000' /nix/store/..."
echo ""
echo "To check cache status:"
echo "  systemctl --user status nix-serve"
echo "  curl http://localhost:5000/nix-cache-info"