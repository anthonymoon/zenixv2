#!/usr/bin/env bash

# Generate secret key for nix-serve binary cache
echo "Generating nix-serve secret key..."

# Create directory if it doesn't exist
sudo mkdir -p /var/keys

# Generate the key pair
nix-store --generate-binary-cache-key nixos-cache-key /var/keys/cache-priv-key.pem /var/keys/cache-pub-key.pem

# Set proper permissions
sudo chmod 600 /var/keys/cache-priv-key.pem
sudo chmod 644 /var/keys/cache-pub-key.pem

echo "Keys generated:"
echo "Private key: /var/keys/cache-priv-key.pem"
echo "Public key: /var/keys/cache-pub-key.pem"
echo ""
echo "Public key contents:"
cat /var/keys/cache-pub-key.pem