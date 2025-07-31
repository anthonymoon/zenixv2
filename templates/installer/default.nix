# Template that generates hardware-specific installer
{ pkgs, lib, ... }:

{
  path = ./.;
  description = "Hardware-specific NixOS installer";
  
  # Script to initialize the template
  welcomeText = ''
    # NixOS Hardware-Specific Installer Template
    
    This template generates a hardware-specific installer configuration.
    
    To use this template:
    
    1. Run hardware detection (as root):
       sudo nix run nixpkgs#nixos-facter -- -o facter.json
    
    2. Install using the generated configuration:
       nix run .#
    
    The installer will:
    - Use the detected hardware from facter.json
    - Automatically select the primary disk
    - Configure UEFI or BIOS based on detection
    - Set up ZFS with optimal settings
    - Install NixOS
  '';
}