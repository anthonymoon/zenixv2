# Workstation profile - desktop productivity
{ config, lib, pkgs, ... }:

{
  imports = [
    ../minimal
  ];
  
  # Desktop packages
  environment.systemPackages = with pkgs; [
    # Browsers
    firefox
    chromium
    
    # Productivity
    libreoffice
    thunderbird
    keepassxc
    
    # Media
    vlc
    mpv
    gimp
    inkscape
    
    # Utilities
    kate
    konsole
    dolphin
    ark
    spectacle
    
    # System
    partition-manager
    filelight
    ksystemlog
  ];
  
  # Enable desktop features
  services.xserver.enable = lib.mkDefault true;
  
  # Printing
  services.printing.enable = true;
  services.avahi = {
    enable = true;
    nssmdns = true;
  };
  
  # Sound
  hardware.pulseaudio.enable = false;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };
  
  # Flatpak support
  services.flatpak.enable = true;
  
  # Enable CUPS
  services.printing.drivers = with pkgs; [
    gutenprint
    hplip
  ];
  
  # Bluetooth
  hardware.bluetooth.enable = true;
  services.blueman.enable = true;
}