{
  meta = {
    description = "Minimal ZFS-based system with essential features only";
    author = "NixOS Templates";
    version = "1.0.0";
    
    features = [
      "zfs-root"
      "minimal-packages"
      "basic-security"
      "lightweight"
    ];
    
    profiles = {
      system = [ "stable" ];
      usage = [ "base" "server" ];
    };
  };
  
  parameters = {
    hostname = {
      type = "string";
      description = "System hostname";
      default = "minimal";
      required = true;
    };
    
    username = {
      type = "string";
      description = "Primary user name";
      default = "user";
      required = true;
    };
    
    disk = {
      type = "string";
      description = "Target disk device";
      default = "/dev/sda";
    };
    
    hostId = {
      type = "string";
      description = "ZFS host ID";
      default = "deadbeef";
    };
  };
  
  examples = [
    "minimal-zfs server base stable"
    "minimal-zfs nas server stable"
  ];
}
