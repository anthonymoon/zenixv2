{ config
, lib
, pkgs
, ...
}: {
  programs.starship = {
    enable = true;

    settings = {
      # Add starship configuration here
      add_newline = true;

      character = {
        success_symbol = "[➜](bold green)";
        error_symbol = "[➜](bold red)";
      };

      # Example modules configuration
      # nix_shell = {
      #   symbol = " ";
      #   format = "via [$symbol$state]($style) ";
      # };
    };
  };
}
