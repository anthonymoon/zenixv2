{ config
, lib
, pkgs
, ...
}: {
  services.xserver = {
    enable = true;
    displayManager.gdm.enable = true;
    desktopManager.gnome.enable = true;
  };

  # GNOME packages
  environment.systemPackages = with pkgs; [
    gnome.gnome-tweaks
    gnome.dconf-editor
    gnomeExtensions.appindicator
    gnomeExtensions.dash-to-dock
    gnomeExtensions.gsconnect
  ];

  # Remove some default GNOME apps
  environment.gnome.excludePackages = with pkgs; [
    gnome-tour
    gnome.geary
    gnome.gnome-music
  ];

  # Enable GNOME features
  services.udev.packages = with pkgs; [ gnome.gnome-settings-daemon ];
}
