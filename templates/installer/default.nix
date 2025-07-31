# Template that generates hardware-specific installer
{ pkgs, lib, ... }:

{
  path = ./.;
  description = "NixOS installer for UEFI AMD systems with NVMe";
  
  welcomeText = ''
    # NixOS Installer - UEFI AMD Systems
    
    This installer is preconfigured for:
    - UEFI boot with systemd-boot
    - AMD CPU (kvm-amd module)
    - NVMe drive at /dev/nvme0n1
    - ZFS root filesystem
    
    To install:
       sudo nix run .
    
    WARNING: This will DESTROY all data on /dev/nvme0n1!
  '';
}