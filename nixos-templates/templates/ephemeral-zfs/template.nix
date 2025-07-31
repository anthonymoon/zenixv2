{
  meta = {
    description = "ZFS ephemeral root system that resets to clean state on every boot";
    author = "NixOS Templates";
    version = "1.0.0";
    
    features = [
      "ephemeral-root"
      "zfs-snapshots"
      "persistent-paths"
      "template-substitution"
      "automated-rollback"
      "comprehensive-documentation"
    ];
    
    profiles = {
      system = [ "stable" "25-05" ];
      usage = [ "headless" "desktop" ];
    };
  };
  
  parameters = {
    hostname = {
      type = "string";
      description = "System hostname (replaces @HOSTNAME@)";
      default = "nixos";
      required = true;
    };
    
    username = {
      type = "string";
      description = "Primary user name (replaces @USERNAME@)";
      default = "user";
      required = true;
    };
    
    disk = {
      type = "string";
      description = "Target disk device (replaces @DISK@)";
      default = "/dev/sda";
      required = true;
    };
    
    hostId = {
      type = "string";
      description = "ZFS host ID (8 hex characters)";
      default = "deadbeef";
      validation = "^[a-fA-F0-9]{8}$";
    };
    
    poolName = {
      type = "string";
      description = "ZFS pool name";
      default = "rpool";
    };
    
    timezone = {
      type = "string";
      description = "System timezone";
      default = "UTC";
    };
  };
  
  examples = [
    "ephemeral-zfs workstation desktop stable"
    "ephemeral-zfs server headless stable"
    "ephemeral-zfs dev-machine desktop 25-05"
  ];
  
  installation = {
    requiresTemplateSubstitution = true;
    placeholders = [ "@HOSTNAME@" "@USERNAME@" "@DISK@" ];
    preInstallSteps = [
      "Generate unique hostId if not provided"
      "Validate ZFS compatibility"
      "Check disk availability"
    ];
  };
}
