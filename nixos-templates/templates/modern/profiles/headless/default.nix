{ config
, lib
, pkgs
, ...
}: {
  # Headless server profile

  # Boot to console with serial support
  boot = {
    kernelParams = [ "console=ttyS0,115200n8" "console=tty0" "console=ttyS0" ];
    loader.timeout = 2;
  };

  # Serial console
  services.getty.autologinUser = null;

  # Disable sound (sound.enable is deprecated in NixOS 24.11+)
  hardware.pulseaudio.enable = false;

  # Disable unnecessary hardware support
  hardware = {
    bluetooth.enable = false;
    graphics.enable = lib.mkForce false;
  };

  # Headless services
  services = {
    # Enable SSH by default
    openssh = {
      enable = true;
      openFirewall = true;
    };

    # Disable GUI services
    printing.enable = false;
    avahi.enable = false;
    xserver.enable = false;
  };

  # Power saving
  powerManagement.cpuFreqGovernor = lib.mkDefault "ondemand";

  # Enable fish shell for amoon user
  programs.fish.enable = true;

  # Minimal packages
  environment.systemPackages = with pkgs; [
    # Remote management
    tmux
    screen
    mosh

    # Monitoring
    htop
    iotop
    nmon

    # Network tools
    tcpdump
    iftop
    nethogs
  ];
}
