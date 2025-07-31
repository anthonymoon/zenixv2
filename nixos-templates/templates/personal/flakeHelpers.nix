inputs:
let
  homeManagerCfg = userPackages: extraImports: {
    home-manager.useGlobalPkgs = false;
    home-manager.extraSpecialArgs = {
      inherit inputs;
    };
    home-manager.users.amoon.imports = [
      inputs.agenix.homeManagerModules.default
      inputs.nix-index-database.homeModules.nix-index
      ./users/amoon/dots.nix
      ./users/amoon/age.nix
    ] ++ extraImports;
    home-manager.backupFileExtension = "bak";
    home-manager.useUserPackages = userPackages;
  };
in
{
  mkNixos = machineHostname: nixpkgsVersion: extraModules: {
    nixosConfigurations.${machineHostname} = nixpkgsVersion.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = {
        inherit inputs;
      };
      modules = [
        ./machines/nixos/_common
        ./machines/nixos/${machineHostname}
        ./modules/email
        ./modules/tg-notify
        inputs.agenix.nixosModules.default
        inputs.disko.nixosModules.disko
        ./users/amoon
        (homeManagerCfg false [ ])
      ] ++ extraModules;
    };
  };
  mkMerge = inputs.nixpkgs.lib.lists.foldl' (
    a: b: inputs.nixpkgs.lib.attrsets.recursiveUpdate a b
  ) { };
}
