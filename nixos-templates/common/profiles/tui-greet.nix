{ config, lib, pkgs, ... }:

{
  # TUI-greet display manager (minimal, terminal-based)
  # Perfect for Hyprland and minimalist setups
  
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --remember --remember-user-session";
        user = "greeter";
      };
    };
  };

  # Ensure other display managers are disabled
  services.displayManager = {
    sddm.enable = lib.mkForce false;
    gdm.enable = lib.mkForce false;
  };
  services.xserver.displayManager = {
    lightdm.enable = lib.mkForce false;
  };

  # TUI-greet specific packages
  environment.systemPackages = with pkgs; [
    greetd.tuigreet
  ];

  # Ensure the greeter user exists
  users.users.greeter = {
    isSystemUser = true;
    group = "greeter";
  };
  users.groups.greeter = {};

  # Console configuration for better TUI experience
  console = {
    font = lib.mkDefault "ter-v32n"; # Better terminal font
    keyMap = lib.mkDefault "us";
    useXkbConfig = true;
  };

  # Fonts for better terminal rendering
  fonts.packages = with pkgs; [
    terminus_font
    tamzen # Terminal font
  ];
}
