{ config, lib, pkgs, ... }:

{
  # GDM display manager (GNOME Display Manager)
  # Works well with GNOME and other desktop environments
  
  services.displayManager.gdm = {
    enable = true;
    wayland = true; # Enable Wayland support by default
  };

  # Ensure other display managers are disabled
  services.displayManager.sddm.enable = lib.mkForce false;
  services.greetd.enable = lib.mkForce false;
  services.xserver.displayManager = {
    lightdm.enable = lib.mkForce false;
  };

  # GDM specific configuration
  services.xserver = {
    enable = true;
    xkb = {
      layout = lib.mkDefault "us";
      variant = lib.mkDefault "";
    };
  };

  # Enable required services for GDM
  services = {
    # GNOME services that GDM depends on
    dbus.enable = true;
    upower.enable = true;
    accounts-daemon.enable = true;
    
    # Authentication
    gnome.gnome-keyring.enable = true;
  };

  # Polkit for authentication dialogs
  security.polkit.enable = true;

  # Font configuration for GDM
  fonts = {
    enableDefaultPackages = true;
    packages = with pkgs; [
      cantarell-fonts # GNOME default font
      noto-fonts
      noto-fonts-emoji
    ];
  };

  # GDM specific environment
  environment.sessionVariables = {
    # Wayland support
    MOZ_ENABLE_WAYLAND = lib.mkDefault "1";
    GDK_BACKEND = lib.mkDefault "wayland,x11";
  };
}
