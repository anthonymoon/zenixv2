{ config
, lib
, pkgs
, inputs
, ...
}: {
  programs.hyprland = {
    enable = true;
    package = inputs.hyprland.packages.${pkgs.system}.hyprland;
  };

  # Wayland session requirements
  services.xserver = {
    enable = true;
    displayManager = {
      sddm = {
        enable = true;
        wayland.enable = true;
      };
    };
  };

  # Essential packages for Hyprland
  environment.systemPackages = with pkgs; [
    waybar
    rofi-wayland
    dunst
    swww # Wallpaper daemon
    kitty
    wl-clipboard
    grim
    slurp
    swappy
    hyprpicker
    hyprlock
    hypridle
    xdg-desktop-portal-hyprland
  ];

  # Enable XDG portal
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  };

  # Session variables
  environment.sessionVariables = {
    WLR_NO_HARDWARE_CURSORS = "1";
    NIXOS_OZONE_WL = "1";
  };
}
