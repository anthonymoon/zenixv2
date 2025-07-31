# Common desktop profile
{ config, lib, pkgs, ... }:

{
  # Enable sound
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };

  # Graphics and display
  hardware = {
    opengl.enable = true;
    bluetooth.enable = lib.mkDefault true;
  };

  # Desktop packages
  environment.systemPackages = with pkgs; [
    # Web browser
    firefox
    
    # Media
    vlc
    
    # Graphics
    gimp
    
    # Office
    libreoffice
    
    # System tools
    pavucontrol
    bluez-tools
    
    # File manager
    dolphin
    
    # Text editor
    kate
    
    # Archive tools
    ark
  ];

  # Desktop services
  services = {
    printing.enable = lib.mkDefault true;
    avahi = {
      enable = lib.mkDefault true;
      nssmdns4 = lib.mkDefault true;
      openFirewall = lib.mkDefault true;
    };
  };

  # Fonts
  fonts = {
    enableDefaultPackages = true;
    packages = with pkgs; [
      noto-fonts
      noto-fonts-cjk
      noto-fonts-emoji
      liberation_ttf
      fira-code
      fira-code-symbols
      hack-font
    ];
  };

  # X11/Wayland support
  services.xserver = {
    enable = lib.mkDefault true;
    xkb = {
      layout = lib.mkDefault "us";
      variant = lib.mkDefault "";
    };
  };

  # Enable touchpad support
  services.libinput.enable = lib.mkDefault true;
}
