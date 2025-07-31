# Shared utility functions following DRY principle
{ lib }:

with lib;

rec {
  # User creation helper
  mkUser = { name, groups ? [ "wheel" ], shell ? null, extraGroups ? [], authorizedKeys ? [] }: {
    ${name} = {
      isNormalUser = true;
      extraGroups = groups ++ extraGroups;
      shell = shell;
      openssh.authorizedKeys.keys = authorizedKeys;
    };
  };
  
  # Batch user creation
  mkUsers = users: mkMerge (map mkUser users);
  
  # Common group sets
  userGroups = {
    base = [ "wheel" ];
    desktop = [ "wheel" "networkmanager" "audio" "video" ];
    development = [ "wheel" "networkmanager" "docker" "libvirtd" "kvm" ];
    full = [ "wheel" "networkmanager" "audio" "video" "docker" "libvirtd" "kvm" ];
  };
  
  # Package group builders
  mkPackageGroup = { name, packages, condition ? true }: 
    mkIf condition packages;
  
  # Common package groups
  packageGroups = {
    base = pkgs: with pkgs; [
      # Core utilities
      coreutils
      curl
      wget
      git
      vim
      htop
      tree
      
      # File management
      rsync
      unzip
      zip
      p7zip
      
      # Hardware tools
      pciutils
      usbutils
      lshw
    ];
    
    compression = pkgs: with pkgs; [
      gzip
      bzip2
      xz
      zip
      unzip
      p7zip
      zstd
      lz4
    ];
    
    monitoring = pkgs: with pkgs; [
      htop
      iotop
      iftop
      nethogs
      lsof
      strace
      tcpdump
    ];
    
    desktop = pkgs: with pkgs; [
      firefox
      chromium
      vlc
      mpv
      gimp
      inkscape
      libreoffice
      thunderbird
    ];
    
    development = pkgs: with pkgs; [
      # Version control
      git
      git-lfs
      tig
      
      # Editors
      neovim
      emacs
      vscode
      
      # Languages
      gcc
      python3
      nodejs
      rustc
      cargo
      go
      
      # Tools
      gnumake
      cmake
      pkg-config
      binutils
      gdb
      valgrind
    ];
    
    networking = pkgs: with pkgs; [
      nmap
      netcat
      socat
      dig
      whois
      traceroute
      mtr
      wireguard-tools
      openvpn
    ];
  };
  
  # Service configuration helpers
  mkSSHConfig = { 
    enable ? true,
    permitRootLogin ? "no",
    passwordAuthentication ? false,
    ports ? [ 22 ],
    extraConfig ? {}
  }: {
    enable = enable;
    ports = ports;
    settings = {
      PermitRootLogin = permitRootLogin;
      PasswordAuthentication = passwordAuthentication;
      KbdInteractiveAuthentication = false;
      UseDns = false;
      X11Forwarding = false;
      PermitEmptyPasswords = false;
    } // extraConfig;
  };
  
  mkPipewireConfig = {
    enable ? true,
    alsa ? true,
    pulse ? true,
    jack ? true,
    support32Bit ? true
  }: {
    enable = enable;
    alsa = {
      enable = alsa;
      support32Bit = support32Bit;
    };
    pulse.enable = pulse;
    jack.enable = jack;
  };
  
  # Firewall configuration helper
  mkFirewallConfig = {
    enable ? true,
    allowedTCPPorts ? [],
    allowedUDPPorts ? [],
    allowPing ? true,
    logRefusedConnections ? false
  }: {
    enable = enable;
    allowedTCPPorts = allowedTCPPorts;
    allowedUDPPorts = allowedUDPPorts;
    allowPing = allowPing;
    logRefusedConnections = logRefusedConnections;
  };
  
  # Boot configuration helpers
  mkSystemdBootConfig = {
    timeout ? 3,
    editor ? false,
    consoleMode ? "auto"
  }: {
    systemd-boot = {
      enable = true;
      editor = editor;
      consoleMode = consoleMode;
      configurationLimit = 10;
    };
    efi.canTouchEfiVariables = true;
    timeout = timeout;
  };
  
  # Common kernel module sets
  kernelModules = {
    base = [ "fuse" ];
    amd = [ "kvm-amd" "amdgpu" ];
    intel = [ "kvm-intel" "i915" ];
    virtualisation = [ "vfio" "vfio_iommu_type1" "vfio_pci" "vfio_virqfd" ];
    storage = [ "nvme" "ahci" "xhci_pci" "usb_storage" "sd_mod" "sdhci_pci" ];
    network = [ "iwlwifi" "iwlmvm" "r8169" "e1000e" ];
  };
  
  # ZFS configuration helper
  mkZFSConfig = {
    hostId,
    forceImportRoot ? false,
    autoScrub ? true,
    autoSnapshot ? true,
    trim ? true,
    arcMax ? null,
    arcMin ? null
  }: {
    boot = {
      supportedFilesystems = [ "zfs" ];
      zfs = {
        forceImportRoot = forceImportRoot;
        forceImportAll = false;
      };
      kernelParams = 
        optional (arcMax != null) "zfs.zfs_arc_max=${toString arcMax}" ++
        optional (arcMin != null) "zfs.zfs_arc_min=${toString arcMin}";
    };
    
    networking.hostId = hostId;
    
    services.zfs = {
      autoScrub = {
        enable = autoScrub;
        interval = "weekly";
      };
      trim.enable = trim;
      autoSnapshot = mkIf autoSnapshot {
        enable = true;
        frequent = 4;
        hourly = 24;
        daily = 7;
        weekly = 4;
        monthly = 12;
      };
    };
  };
  
  # Desktop environment helpers
  mkDesktopConfig = de: 
    if de == "kde" then {
      services.xserver.desktopManager.plasma5.enable = true;
      services.displayManager.sddm.enable = true;
    }
    else if de == "gnome" then {
      services.xserver.desktopManager.gnome.enable = true;
      services.xserver.displayManager.gdm.enable = true;
    }
    else if de == "xfce" then {
      services.xserver.desktopManager.xfce.enable = true;
      services.displayManager.lightdm.enable = true;
    }
    else {};
  
  # Merge multiple configurations with proper precedence
  mergeConfigs = configs: mkMerge configs;
  
  # Conditional configuration helper
  mkConditionalConfig = condition: config: mkIf condition config;
}