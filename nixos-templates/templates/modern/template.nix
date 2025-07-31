{
  meta = {
    description = "Modern NixOS system with dynamic configuration and auto-hardware detection";
    author = "NixOS Templates";
    version = "1.0.0";
    
    features = [
      "auto-hardware-detection"
      "profile-composition" 
      "performance-optimization"
      "modular-architecture"
      "pre-commit-hooks"
      "dynamic-builds"
    ];
    
    profiles = {
      desktop = [ "kde" "gnome" "hyprland" "niri" ];
      system = [ "stable" "unstable" "hardened" "chaotic" ];
      usage = [ "gaming" "headless" "development" ];
    };
  };
  
  parameters = {
    hostname = {
      type = "string";
      description = "System hostname";
      default = "workstation";
      required = true;
    };
    
    username = {
      type = "string"; 
      description = "Primary user name";
      default = "user";
      required = true;
    };
    
    autoHardware = {
      type = "boolean";
      description = "Enable automatic hardware detection";
      default = true;
    };
    
    performanceOptimization = {
      type = "boolean";
      description = "Enable comprehensive performance optimizations";
      default = true;
    };
    
    disk = {
      type = "string";
      description = "Target disk for installation";
      default = "/dev/sda";
    };
  };
  
  examples = [
    "modern workstation desktop kde stable"
    "modern laptop desktop hyprland gaming unstable"
    "modern server headless hardened stable"
    "modern gaming-rig desktop kde gaming chaotic"
  ];
}
