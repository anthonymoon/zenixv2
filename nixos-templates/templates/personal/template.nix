{
  meta = {
    description = "Personal configuration with dotfiles management and age encryption";
    author = "NixOS Templates";
    version = "1.0.0";
    
    features = [
      "dotfiles-management"
      "age-encryption"
      "home-manager"
      "user-configuration"
      "personal-settings"
    ];
    
    profiles = {
      desktop = [ "kde" "hyprland" ];
      system = [ "stable" "unstable" ];
    };
  };
  
  parameters = {
    hostname = {
      type = "string";
      description = "Personal system hostname";
      default = "personal";
      required = true;
    };
    
    username = {
      type = "string";
      description = "Your username";
      default = "user";
      required = true;
    };
    
    email = {
      type = "string";
      description = "Your email address";
      default = "user@example.com";
    };
    
    gitSigningKey = {
      type = "string";
      description = "GPG key ID for git signing";
      default = "";
    };
  };
  
  examples = [
    "personal laptop desktop kde stable"
    "personal workstation desktop hyprland unstable"
  ];
}
