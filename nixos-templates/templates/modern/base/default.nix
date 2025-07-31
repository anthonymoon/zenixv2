{ config
, lib
, pkgs
, ...
}: {
  # Minimal base configuration for all systems

  # Locale settings
  time.timeZone = lib.mkDefault "UTC";
  i18n.defaultLocale = lib.mkDefault "en_US.UTF-8";

  # Console
  console = {
    font = "Lat2-Terminus16";
    keyMap = lib.mkDefault "us";
  };

  # Basic boot settings
  boot = {
    tmp.cleanOnBoot = true;
    kernel.sysctl = {
      "kernel.sysrq" = 1;
      "net.ipv4.ip_forward" = 1;
    };
  };

  # Essential system packages (absolute minimum)
  environment.systemPackages = with pkgs; [
    vim
    git
    htop
    tmux
  ];

  # Basic networking
  networking = {
    useDHCP = lib.mkDefault true;
    firewall.enable = lib.mkDefault true;

    # Add cachy.local to /etc/hosts for binary cache
    extraHosts = ''
      10.10.10.10 cachy.local
    '';
  };

  # Enable basic services
  services = {
    openssh = {
      enable = lib.mkDefault true;
      settings = {
        PermitRootLogin = lib.mkDefault "prohibit-password";
        PasswordAuthentication = lib.mkDefault false;
      };
    };
  };

  # Security basics
  security = {
    sudo.enable = true;
    sudo.wheelNeedsPassword = lib.mkDefault true;
  };
}
