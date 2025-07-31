{
  meta = {
    description = "System optimized for automated deployment and remote management";
    author = "NixOS Templates";
    version = "1.0.0";
    
    features = [
      "remote-deployment"
      "automated-installation"
      "template-substitution"
      "deployment-scripts"
    ];
    
    profiles = {
      target = [ "remote" "local" "vm" ];
      system = [ "stable" ];
    };
  };
  
  parameters = {
    hostname = {
      type = "string";
      description = "Target system hostname";
      default = "deploy-target";
      required = true;
    };
    
    username = {
      type = "string";
      description = "Deployment user name";
      default = "deploy";
      required = true;
    };
    
    disk = {
      type = "string";
      description = "Target disk device";
      default = "/dev/sda";
    };
    
    remoteHost = {
      type = "string";
      description = "Remote host IP or FQDN";
      default = "";
    };
    
    sshKey = {
      type = "string";
      description = "SSH public key for access";
      default = "";
    };
  };
  
  examples = [
    "deployment remote-server remote stable"
    "deployment local-vm local stable" 
    "deployment test-vm vm stable"
  ];
}
