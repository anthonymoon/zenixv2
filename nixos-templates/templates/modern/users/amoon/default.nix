{ config
, lib
, pkgs
, ...
}: {
  users.users.amoon = {
    isNormalUser = true;
    home = "/home/amoon";
    description = "Main user account";
    extraGroups = [
      "wheel" # Admin privileges
      "networkmanager" # Network configuration
      "docker" # Docker access
      "libvirtd" # Virtualization
      "kvm" # KVM virtualization
      "audio" # Audio devices
      "video" # Video devices
      "dialout" # Serial ports
      "disk" # Direct disk access
      "media" # Media group
    ];
    shell = pkgs.fish;
    openssh.authorizedKeys.keys = [
      # Add your SSH public keys here
    ];
  };
}
