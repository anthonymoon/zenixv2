{ config
, lib
, pkgs
, ...
}: {
  # Niri compositor
  programs.niri.enable = true;

  # Wayland session requirements
  services.xserver = {
    enable = true;
    displayManager.gdm = {
      enable = true;
      wayland = true;
    };
  };

  # Essential packages for Niri
  environment.systemPackages = with pkgs; [
    waybar
    fuzzel # Application launcher
    mako # Notification daemon
    kitty
    wl-clipboard
    grim
    slurp
    swappy
    xdg-desktop-portal-gtk
    xdg-desktop-portal-wlr
  ];

  # Enable XDG portal
  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
      xdg-desktop-portal-wlr
    ];
  };

  # Session variables
  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
  };
}
