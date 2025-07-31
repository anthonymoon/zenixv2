# Template parameter substitution module
{ config, lib, pkgs, templateParams ? {}, ... }:

let
  # Helper function to substitute template parameters
  substitute = text: params:
    lib.foldl' (acc: param:
      let
        placeholder = "@${lib.toUpper param}@";
        value = toString (params.${param} or placeholder);
      in
      lib.replaceStrings [placeholder] [value] acc
    ) text (lib.attrNames params);

  # Common parameter validation
  validateParams = params: required:
    let
      missing = lib.filter (param: !(params ? ${param})) required;
    in
    if missing != []
    then throw ''
      Missing required template parameters: ${lib.concatStringsSep ", " missing}
      
      Please provide these parameters using:
        --param ${lib.concatStringsSep " --param " (map (p: "${p}=<value>") missing)}
      
      Or in your configuration:
        templateParams = {
          ${lib.concatStringsSep "\n          " (map (p: "${p} = \"value\";") missing)}
        };
    ''
    else params;

in {
  options = {
    templateSubstitution = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable template parameter substitution";
      };
      
      parameters = lib.mkOption {
        type = lib.types.attrsOf lib.types.str;
        default = templateParams;
        description = "Template parameters for substitution";
      };
      
      requiredParams = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ "hostname" ];
        description = "Required template parameters";
      };
    };
  };

  config = lib.mkIf config.templateSubstitution.enable {
    # Validate required parameters
    assertions = [{
      assertion = 
        let missing = lib.filter (param: !(config.templateSubstitution.parameters ? ${param})) 
                      config.templateSubstitution.requiredParams;
        in missing == [];
      message = let
        missing = lib.filter (param: !(config.templateSubstitution.parameters ? ${param})) 
                  config.templateSubstitution.requiredParams;
      in ''
        Missing required template parameters: ${lib.concatStringsSep ", " missing}
        
        These parameters are required for this template to function properly.
        Please add them to your configuration:
        
        templateSubstitution.parameters = {
          ${lib.concatStringsSep "\n          " (map (p: "${p} = \"your-value-here\";") missing)}
        };
      '';
    }];

    # Set hostname from parameters
    networking.hostName = lib.mkDefault (
      config.templateSubstitution.parameters.hostname or "nixos"
    );

    # Store parameters in system configuration
    environment.etc."nixos-templates/parameters.json".text = 
      builtins.toJSON config.templateSubstitution.parameters;
  };
}
