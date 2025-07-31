{ inputs }:
let
  inherit (inputs.nixpkgs) lib;
in
{
  # Main system builder function
  mkSystem = {
    hostname,
    system ? "x86_64-linux",
    modules ? [],
    specialArgs ? {}
  }: inputs.nixpkgs.lib.nixosSystem {
    inherit system;
    specialArgs = specialArgs // {
      inherit inputs hostname;
    };
    modules = [
      # Host-specific configuration
      { networking.hostName = hostname; }
    ] ++ modules;
  };

  # Profile builder
  mkProfile = {
    name,
    imports ? [],
    config ? {},
    options ? {}
  }: { lib, ... }: {
    imports = imports;
    options = options;
    config = lib.mkIf config."profiles.${name}.enable" config;
  };

  # Hardware detection helpers
  hardware = {
    # CPU detection
    detectCPU = { lib, ... }: {
      hardware.cpu = 
        if builtins.pathExists "/proc/cpuinfo" then
          let
            cpuinfo = builtins.readFile "/proc/cpuinfo";
            isIntel = lib.hasInfix "GenuineIntel" cpuinfo;
            isAMD = lib.hasInfix "AuthenticAMD" cpuinfo;
          in
          if isIntel then "intel"
          else if isAMD then "amd"
          else "generic"
        else "generic";
    };

    # GPU detection
    detectGPU = { lib, pkgs, ... }: {
      hardware.gpu = 
        let
          pciDevices = if builtins.pathExists "/sys/bus/pci/devices" 
            then builtins.readDir "/sys/bus/pci/devices"
            else {};
          hasNvidia = lib.any (dev: lib.hasInfix "10de" dev) (lib.attrNames pciDevices);
          hasAMD = lib.any (dev: lib.hasInfix "1002" dev) (lib.attrNames pciDevices);
          hasIntel = lib.any (dev: lib.hasInfix "8086" dev) (lib.attrNames pciDevices);
        in
        if hasNvidia then "nvidia"
        else if hasAMD then "amd"
        else if hasIntel then "intel"
        else "none";
    };

    # Platform detection
    detectPlatform = { lib, ... }: {
      hardware.platform = 
        if builtins.pathExists "/sys/class/dmi/id/sys_vendor" then
          let vendor = lib.removeSuffix "\n" (builtins.readFile "/sys/class/dmi/id/sys_vendor");
          in
          if vendor == "System76" then "system76"
          else if vendor == "Dell Inc." then "dell"
          else if vendor == "LENOVO" then "lenovo"
          else if vendor == "ASUSTeK COMPUTER INC." then "asus"
          else if lib.hasInfix "Apple" vendor then "apple"
          else "generic"
        else "generic";
    };
  };

  # Common helper functions
  helpers = {
    # Generate ZFS host ID from hostname
    mkHostId = hostname: 
      builtins.substring 0 8 (builtins.hashString "sha256" hostname);

    # Check if running on NVMe
    hasNVMe = 
      builtins.pathExists "/dev/nvme0n1";

    # Check if running on SSD
    hasSSD = device:
      let
        rotational = "/sys/block/${device}/queue/rotational";
      in
      builtins.pathExists rotational && 
      builtins.readFile rotational == "0\n";

    # Format bytes to human readable
    formatBytes = bytes:
      let
        units = [ "B" "KB" "MB" "GB" "TB" ];
        go = n: u:
          if n < 1024 || u == 4
          then "${toString n}${builtins.elemAt units u}"
          else go (n / 1024) (u + 1);
      in
      go bytes 0;
  };

  # Module builders
  builders = {
    # Build a service module
    mkServiceModule = { name, description, config }: { config, lib, ... }: {
      options.services.${name} = {
        enable = lib.mkEnableOption description;
      };
      
      config = lib.mkIf config.services.${name}.enable config;
    };

    # Build a program module
    mkProgramModule = { name, package, config ? {} }: { config, lib, pkgs, ... }: {
      options.programs.${name} = {
        enable = lib.mkEnableOption "the ${name} program";
        package = lib.mkPackageOption pkgs name { };
      };
      
      config = lib.mkIf config.programs.${name}.enable (
        lib.mkMerge [
          {
            environment.systemPackages = [ config.programs.${name}.package ];
          }
          config
        ]
      );
    };
  };

  # Assertion helpers
  assertions = {
    # Assert ZFS is properly configured
    assertZFS = config: {
      assertion = config.boot.supportedFilesystems.zfs or false;
      message = "ZFS support must be enabled";
    };

    # Assert minimum RAM for ZFS
    assertMinRAM = minGB: config: {
      assertion = config.hardware.memorySize >= (minGB * 1024 * 1024 * 1024);
      message = "System requires at least ${toString minGB}GB of RAM";
    };

    # Assert security settings
    assertSecurity = config: {
      assertion = !config.security.mitigations.disable;
      message = "Security mitigations should not be disabled in production";
    };
  };
}