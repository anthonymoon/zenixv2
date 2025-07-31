{ config
, lib
, pkgs
, ...
}: {
  # Security hardened profile

  # Hardened kernel
  boot.kernelPackages = lib.mkDefault pkgs.linuxPackages_hardened;

  # Security kernel parameters
  boot.kernelParams = [
    "slab_nomerge"
    "page_alloc.shuffle=1"
    "pti=on"
    "vsyscall=none"
    "debugfs=off"
    "oops=panic"
    "quiet"
    "loglevel=0"
  ];

  # Security settings
  security = {
    lockKernelModules = true;
    protectKernelImage = true;
    forcePageTableIsolation = true;
    virtualisation.flushL1DataCache = "always";

    apparmor = {
      enable = true;
      killUnconfinedConfinables = true;
    };

    audit = {
      enable = true;
      rules = [
        "-w /etc/passwd -p wa -k identity"
        "-w /etc/group -p wa -k identity"
        "-w /etc/shadow -p wa -k identity"
      ];
    };
  };

  # Firewall
  networking.firewall = {
    enable = true;
    allowPing = false;
    logReversePathDrops = true;
    logRefusedConnections = true;
  };

  # Disable unnecessary services
  services = {
    avahi.enable = false;
    cups.enable = false;
    printing.enable = false;
  };

  # Restrict nix
  nix.settings = {
    allowed-users = [ "@wheel" ];
    trusted-users = [ "root" ];
    sandbox = true;
  };

  # Harden SSH
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      X11Forwarding = false;
    };
    extraConfig = ''
      Protocol 2
      StrictModes yes
      IgnoreRhosts yes
      HostbasedAuthentication no
      PermitEmptyPasswords no
      PermitUserEnvironment no
      Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com
      MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com
      KexAlgorithms curve25519-sha256,curve25519-sha256@libssh.org
      ClientAliveInterval 300
      ClientAliveCountMax 2
    '';
  };
}
