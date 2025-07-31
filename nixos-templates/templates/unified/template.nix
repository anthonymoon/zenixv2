{
  meta = {
    description = "Unified disko-based system with simple configuration";
    author = "NixOS Templates";
    version = "1.0.0";
    
    features = [
      "disko-integration"
      "simple-configuration"
      "standard-layout"
    ];
    
    profiles = {
      system = [ "stable" ];
      usage = [ "desktop" "server" ];
    };
  };
  
  parameters = {
    hostname = {
      type = "string";
      description = "System hostname";
      default = "unified";
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
  };
  
  examples = [
    "unified desktop-system desktop stable"
    "unified file-server server stable"
  ];
}
