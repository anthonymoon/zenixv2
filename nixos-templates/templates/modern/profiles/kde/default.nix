{ config
, lib
, pkgs
, ...
}: {
  # Enable X11 and Plasma 6
  services.xserver.enable = true;
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;

  # Basic KDE packages - minimal set to avoid package conflicts
  environment.systemPackages = with pkgs; [
    # Core KDE applications
    kdePackages.konsole
    kdePackages.dolphin
    kdePackages.kate
    kdePackages.ark
    kdePackages.okular
    kdePackages.spectacle

    # System utilities
    firefox
    git
    vim
  ];

  # Enable KDE partition manager
  programs.partition-manager.enable = true;

  # KDE Connect firewall (if needed)
  networking.firewall = {
    allowedTCPPortRanges = [
      {
        from = 1714;
        to = 1764;
      }
    ];
    allowedUDPPortRanges = [
      {
        from = 1714;
        to = 1764;
      }
    ];
  };
}
