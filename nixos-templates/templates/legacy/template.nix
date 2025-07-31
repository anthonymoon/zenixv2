{
  meta = {
    description = "Legacy and testing configurations for experimental features";
    author = "NixOS Templates";
    version = "1.0.0";
    
    features = [
      "version-testing"
      "experimental-features"
      "25-11-pre-support"
    ];
    
    profiles = {
      version = [ "25-11-pre" ];
      usage = [ "testing" ];
    };
  };
  
  parameters = {
    hostname = {
      type = "string";
      description = "Test system hostname";
      default = "test";
      required = true;
    };
    
    username = {
      type = "string";
      description = "Test user name";
      default = "test";
      required = true;
    };
    
    disk = {
      type = "string";
      description = "Target disk device";
      default = "/dev/sda";
    };
  };
  
  examples = [
    "legacy test-system testing 25-11-pre"
  ];
}
