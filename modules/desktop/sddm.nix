# SDDM display manager configuration
{ config, lib, pkgs, ... }:

{
  # Disable greetd if it's enabled elsewhere
  services.greetd.enable = lib.mkForce false;
  
  # Enable SDDM
  services.xserver = {
    enable = true;
    displayManager.sddm = {
      enable = true;
      wayland.enable = true;
      theme = "breeze";
      settings = {
        General = {
          DisplayServer = "wayland";
        };
        Wayland = {
          SessionDir = "${pkgs.hyprland}/share/wayland-sessions";
        };
      };
    };
  };

  # SDDM Wayland session support
  environment.systemPackages = with pkgs; [
    libsForQt5.qt5.qtwayland
    qt6.qtwayland
  ];
}