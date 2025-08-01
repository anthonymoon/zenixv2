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
    
    # Terminal emulators
    kitty
    alacritty
    
    # File managers
    nautilus
    ranger
    
    # Utilities
    gparted
    baobab
  ];
  
  # Desktop features are handled by Hyprland module
  
  # Printing
  services.printing.enable = true;
  services.avahi = {
    enable = true;
    nssmdns4 = true;
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