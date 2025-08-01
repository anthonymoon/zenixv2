# Samba configuration optimized for 20Gbps
{ config, lib, pkgs, ... }:

{
  services.samba = {
    enable = true;
    openFirewall = true;
    
    # Security mode
    securityType = "user";
    
    # Global settings optimized for 20Gbps
    extraConfig = ''
      # Basic settings
      workgroup = WORKGROUP
      server string = Nixie Samba Server
      server role = standalone server
      
      # Performance optimizations for 20Gbps
      socket options = TCP_NODELAY IPTOS_LOWDELAY SO_RCVBUF=131072 SO_SNDBUF=131072
      use sendfile = yes
      min receivefile size = 16384
      aio read size = 16384
      aio write size = 16384
      write cache size = 524288
      
      # Increase buffers
      max xmit = 65535
      dead time = 30
      getwd cache = yes
      
      # SMB3 multi-channel for bonded interfaces
      server multi channel support = yes
      
      # Performance tuning
      strict locking = no
      strict sync = no
      sync always = no
      
      # Large read/write support
      large readwrite = yes
      
      # Async I/O
      aio max threads = 256
      
      # Enable SMB3
      server min protocol = SMB2
      server max protocol = SMB3
      client min protocol = SMB2
      client max protocol = SMB3
      
      # Security
      map to guest = Never
      guest account = nobody
      
      # Disable printing
      load printers = no
      printing = bsd
      printcap name = /dev/null
      disable spoolss = yes
      
      # Logging
      log file = /var/log/samba/log.%m
      max log size = 1000
      logging = file
    '';
    
    shares = {
      # Example share - modify as needed
      data = {
        path = "/srv/samba/data";
        browseable = "yes";
        "read only" = "no";
        "guest ok" = "no";
        "create mask" = "0644";
        "directory mask" = "0755";
        "force user" = "smbuser";
        "force group" = "smbgroup";
        # Performance options per share
        "strict sync" = "no";
        "sync always" = "no";
        "use sendfile" = "yes";
        "aio read size" = "16384";
        "aio write size" = "16384";
        "write cache size" = "524288";
        # VFS objects for better performance
        "vfs objects" = "aio_pthread";
      };
    };
  };
  
  # Create samba user and group
  users.users.smbuser = {
    isSystemUser = true;
    group = "smbgroup";
    home = "/var/empty";
    shell = pkgs.shadow.nologin;
  };
  
  users.groups.smbgroup = {};
  
  # Create data directory
  systemd.tmpfiles.rules = [
    "d /srv/samba/data 0755 smbuser smbgroup -"
  ];
  
  # Firewall rules for Samba
  networking.firewall = {
    allowedTCPPorts = [ 139 445 ];
    allowedUDPPorts = [ 137 138 ];
  };
  
  # Enable Avahi for network discovery
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    publish = {
      enable = true;
      addresses = true;
      workstation = true;
      userServices = true;
    };
    extraServiceFiles = {
      smb = ''
        <?xml version="1.0" standalone='no'?>
        <!DOCTYPE service-group SYSTEM "avahi-service.dtd">
        <service-group>
          <name replace-wildcards="yes">%h</name>
          <service>
            <type>_smb._tcp</type>
            <port>445</port>
          </service>
        </service-group>
      '';
    };
  };
}