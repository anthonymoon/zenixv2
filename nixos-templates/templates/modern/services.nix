{ config
, pkgs
, lib
, ...
}: {
  # SSH service
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
  };

  # Avahi service
  services.avahi = {
    enable = true;
    nssmdns = true;
    publish = {
      enable = true;
      addresses = true;
      workstation = true;
    };
  };

  # NGINX service
  services.nginx = {
    enable = true;
    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;
  };

  # Libvirt virtualization
  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      package = pkgs.qemu_kvm;
      runAsRoot = true;
      swtpm.enable = true;
      ovmf = {
        enable = true;
        packages = [ pkgs.OVMFFull.fd ];
      };
    };
  };

  # Docker
  virtualisation.docker = {
    enable = true;
    enableNvidia = true;
  };

  # Samba
  services.samba = {
    enable = true;
    securityType = "user";
    openFirewall = true;
    extraConfig = ''
      workgroup = WORKGROUP
      server string = NixOS Samba Server
      netbios name = nixos
      security = user
      use sendfile = yes
      min protocol = SMB2
      # Performance optimizations
      socket options = TCP_NODELAY SO_RCVBUF=8192 SO_SNDBUF=8192
      read raw = yes
      write raw = yes
      max xmit = 65535
      dead time = 15
      getwd cache = yes
    '';
  };

  # Samba WSDD for Windows discovery
  services.samba-wsdd = {
    enable = true;
    workgroup = "WORKGROUP";
  };

  # ZFS services
  services.zfs = {
    autoScrub.enable = true;
    autoSnapshot.enable = true;
    trim.enable = true;
  };

  # Btrfs maintenance
  services.btrfs.autoScrub = {
    enable = true;
    interval = "weekly";
    fileSystems = [ "/" ];
  };

  # SMART monitoring
  services.smartd = {
    enable = true;
    autodetect = true;
  };

  # Sensors
  hardware.sensor.iio.enable = true;

  # Cockpit web management
  services.cockpit = {
    enable = true;
    port = 9090;
  };

  # Time synchronization
  services.timesyncd.enable = true;

  # Adguard Home DNS
  services.adguardhome = {
    enable = true;
    mutableSettings = true;
    settings = {
      bind_host = "0.0.0.0";
      bind_port = 3000;
      dns = {
        bind_hosts = [ "0.0.0.0" ];
        port = 53;
        upstream_dns = [
          "94.140.14.14"
          "94.140.15.15"
        ];
      };
    };
  };

  # Jackett
  services.jackett = {
    enable = true;
    openFirewall = true;
  };

  # Nix serve
  services.nix-serve = {
    enable = true;
    secretKeyFile = "/var/keys/cache-priv-key.pem";
    port = 5000;
  };

  # Enable CUPS for printing
  services.printing.enable = false;

  # Enable sound
  sound.enable = true;
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Performance governor
  powerManagement.cpuFreqGovernor = "performance";

  # System timers
  systemd.timers = {
    "btrfs-maintenance" = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "weekly";
        Persistent = true;
      };
    };

    "auto-rollback" = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "daily";
        Persistent = true;
      };
    };

    "snapper-cleanup" = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "daily";
        Persistent = true;
      };
    };

    "snapper-cleanup-aggressive" = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "weekly";
        Persistent = true;
      };
    };

    "snapper-timeline" = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "hourly";
        Persistent = true;
      };
    };
  };

  # Additional systemd services
  systemd.services = {
    "nvme-watchdog" = {
      description = "NVMe Watchdog";
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.bash}/bin/bash -c 'while true; do nvme list > /dev/null 2>&1; sleep 60; done'";
        Restart = "always";
      };
    };
  };

  # Firewall configuration
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [
      22 # SSH
      80 # HTTP
      443 # HTTPS
      9090 # Cockpit
      445 # SMB
      139 # NetBIOS
      9117 # Jackett
      5000 # Nix serve
    ];
    allowedUDPPorts = [
      137 # NetBIOS
      138 # NetBIOS
      3702 # WSDD
    ];
  };
}
