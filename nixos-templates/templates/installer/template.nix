{
  meta = {
    description = "ZFS installer configuration for automated deployment";
    author = "NixOS Templates";
    version = "1.0.0";
    
    features = [
      "installation-focused"
      "zfs-setup"
      "automated-partitioning"
    ];
    
    profiles = {
      target = [ "installer" ];
      system = [ "stable" ];
    };
  };
  
  parameters = {
    hostname = {
      type = "string";
      description = "Target system hostname";
      default = "installer";
      required = true;
    };
    
    disk = {
      type = "string";
      description = "Target disk device";
      default = "/dev/sda";
    };
  };
  
  examples = [
    "installer zfs-setup installer stable"
  ];
}
