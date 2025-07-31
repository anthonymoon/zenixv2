# Simplified library functions following NixOS best practices
{ inputs }:
let
  inherit (inputs.nixpkgs) lib;
in
{
  # Instead of complex mkSystem builder, just use nixosSystem directly
  # in flake.nix with clear, visible configuration
  
  # Simple helper to generate host ID from hostname (actually useful)
  mkHostId = hostname: 
    builtins.substring 0 8 (builtins.hashString "sha256" hostname);
  
  # Format bytes - actually useful utility
  formatBytes = bytes:
    let
      units = [ "B" "KB" "MB" "GB" "TB" ];
      go = n: u:
        if n < 1024 || u == 4
        then "${toString n}${builtins.elemAt units u}"
        else go (n / 1024) (u + 1);
    in
    go bytes 0;
  
  # Simple assertions that are actually useful
  assertions = {
    # Assert minimum RAM for ZFS
    assertMinRAM = minGB: config: {
      assertion = config.hardware.memorySize >= (minGB * 1024 * 1024 * 1024);
      message = "System requires at least ${toString minGB}GB of RAM";
    };
  };
}