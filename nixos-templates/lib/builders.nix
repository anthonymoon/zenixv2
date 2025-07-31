{ lib, inputs, system, nixpkgs, nixpkgs-stable, nixpkgs-25-05 }:

let
  # Helper to select nixpkgs based on profile
  selectNixpkgs = profiles:
    if lib.elem "unstable" profiles then nixpkgs
    else if lib.elem "25-05" profiles then nixpkgs-25-05
    else nixpkgs-stable;

  # Common module imports
  commonModules = [
    inputs.disko.nixosModules.disko
  ];

in rec {
  # Build a system from template and configuration
  buildSystem = { template, hostname, profiles ? [], params ? {} }:
    let
      selectedNixpkgs = selectNixpkgs profiles;
      
      # Template-specific modules based on features
      templateModules = [
        # Use DRY base module instead of the old one
        ../common/modules/base-dry.nix
        ../common/modules/substitution.nix
        ../common/modules/zfs-workstation.nix
        ../common/modules/workstation-services.nix
        ../common/modules/dev-tools.nix
        # DRY modules are imported by base-dry.nix
      ];

      # Profile mapping for cleaner code and easier maintenance
      profileMap = {
        # Desktop environments (using DRY versions where available)
        desktop = ../common/profiles/desktop-dry.nix;
        headless = ../common/profiles/headless.nix;
        kde = ../common/profiles/kde-dry.nix;
        gnome = ../common/profiles/gnome.nix;
        hyprland = ../common/profiles/hyprland.nix;
        
        # Display managers
        tui-greet = ../common/profiles/tui-greet.nix;
        gdm = ../common/profiles/gdm.nix;
        
        # System versions
        stable = ../common/profiles/stable.nix;
        unstable = ../common/profiles/unstable.nix;
        hardened = ../common/profiles/hardened.nix;
        
        # Usage types
        gaming = ../common/profiles/gaming.nix;
        development = ../common/profiles/development.nix;
      };
      
      # Profile modules from common profiles
      profileModules = lib.filter (path: path != null && builtins.pathExists path) (
        map (profile: profileMap.${profile} or null) profiles
      );

    in
    selectedNixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = { 
        inherit inputs params hostname;
        templateParams = params // { inherit hostname; };
      };
      modules = commonModules ++ templateModules ++ profileModules ++ [
        # Base system configuration
        ({ config, ... }: {
          system.stateVersion = "24.11";
          networking.hostName = hostname;
        })
      ];
    };

  # Build modern template configurations
  buildModernConfigurations = templateInfo:
    let
      examples = [
        { hostname = "workstation"; profiles = [ "desktop" "kde" "stable" ]; }
        { hostname = "laptop"; profiles = [ "desktop" "hyprland" "unstable" ]; }
        { hostname = "server"; profiles = [ "headless" "stable" ]; }
        { hostname = "gaming"; profiles = [ "desktop" "kde" "gaming" "chaotic" ]; }
      ];
    in
    lib.listToAttrs (map (config: {
      name = "${config.hostname}.modern.${lib.concatStringsSep "." config.profiles}";
      value = buildSystem {
        template = "modern";
        inherit (config) hostname profiles;
      };
    }) examples);

  # Build ZFS template configurations
  buildZfsConfigurations = templateInfo:
    let
      examples = [
        { hostname = "zfs-workstation"; profiles = [ "desktop" "stable" ]; }
        { hostname = "zfs-server"; profiles = [ "headless" "stable" ]; }
      ];
    in
    lib.listToAttrs (map (config: {
      name = "${config.hostname}.ephemeral-zfs.${lib.concatStringsSep "." config.profiles}";
      value = buildSystem {
        template = "ephemeral-zfs";
        inherit (config) hostname profiles;
        params = {
          hostId = "deadbeef";
          poolName = "rpool";
        };
      };
    }) examples);

  # Build minimal configurations
  buildMinimalConfigurations = templateInfo:
    let
      examples = [
        { hostname = "minimal-server"; profiles = [ "base" "stable" ]; }
        { hostname = "minimal-nas"; profiles = [ "server" "stable" ]; }
      ];
    in
    lib.listToAttrs (map (config: {
      name = "${config.hostname}.minimal-zfs.${lib.concatStringsSep "." config.profiles}";
      value = buildSystem {
        template = "minimal-zfs";
        inherit (config) hostname profiles;
      };
    }) examples);

  # Template instantiation with parameter substitution
  instantiateTemplate = templatePath: params:
    let
      # Read template files and substitute parameters
      substituteInFile = filePath: content:
        lib.foldl' (acc: param: 
          let
            placeholder = "@${lib.toUpper param}@";
            value = params.${param} or placeholder;
          in
          lib.replaceStrings [placeholder] [value] acc
        ) content (lib.attrNames params);

      # Process template directory
      processTemplate = path:
        if lib.pathExists path
        then substituteInFile path (builtins.readFile path)
        else null;

    in processTemplate templatePath;

  # Validate template parameters with detailed error reporting
  validateTemplate = template: params:
    let
      templateDef = import ../lib/templates.nix { inherit lib; };
      requiredParams = templateDef.templateParameters.common // 
        (templateDef.templateParameters."${template}-specific" or {});
      
      missingParams = lib.filter (param: !(params ? ${param})) 
        (lib.attrNames requiredParams);
      
      invalidParams = lib.filter (param:
        let
          paramDef = requiredParams.${param} or {};
          value = params.${param} or null;
          validation = paramDef.validation or null;
        in
        params ? ${param} && validation != null && !(builtins.match validation value != null)
      ) (lib.attrNames requiredParams);
      
      # Generate helpful error messages
      errorMessage = 
        lib.optionalString (missingParams != []) ''
          Missing required parameters: ${lib.concatStringsSep ", " missingParams}
          
          Required parameters:
          ${lib.concatStringsSep "\n" (map (p: 
            "  - ${p}: ${(requiredParams.${p} or {}).description or "No description"}"
          ) missingParams)}
        '' +
        lib.optionalString (invalidParams != []) ''
          
          Invalid parameter values:
          ${lib.concatStringsSep "\n" (map (p:
            let
              paramDef = requiredParams.${p} or {};
              value = params.${p};
            in
            "  - ${p}: '${toString value}' (expected: ${paramDef.description or "valid format"})"
          ) invalidParams)}
        '';

    in {
      valid = missingParams == [] && invalidParams == [];
      missingParams = missingParams;
      invalidParams = invalidParams;
      errorMessage = errorMessage;
    };

  # Dynamic configuration parser (from nixos-fun)
  parseConfigName = name:
    let
      parts = lib.splitString "." name;
      hostname = builtins.head parts;
      template = if builtins.length parts > 1 then builtins.elemAt parts 1 else "modern";
      profiles = if builtins.length parts > 2 then lib.drop 2 parts else [];
    in {
      inherit hostname template profiles;
    };

  # Build configuration from name string
  buildFromName = name: params:
    let
      parsed = parseConfigName name;
    in
    buildSystem {
      inherit (parsed) template hostname profiles;
      inherit params;
    };

  # Template discovery
  discoverTemplates = templateDir:
    let
      isTemplate = name: type: 
        type == "directory" && lib.pathExists "${templateDir}/${name}/template.nix";
      
      templateDirs = lib.filterAttrs isTemplate (builtins.readDir templateDir);
    in
    lib.mapAttrs (name: _: {
      path = "${templateDir}/${name}";
      config = import "${templateDir}/${name}/template.nix";
    }) templateDirs;
}
