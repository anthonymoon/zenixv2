{ config
, lib
, pkgs
, ...
}: {
  programs.fish = {
    enable = true;

    shellAbbrs = {
      # Add fish abbreviations here
    };

    shellAliases = {
      # Add fish aliases here
    };

    shellInit = ''
      # Add any fish initialization here
    '';

    interactiveShellInit = ''
      # Add interactive shell initialization here
    '';

    promptInit = ''
      # Prompt initialization (if not using starship)
    '';

    functions = {
      # Define custom fish functions here
    };
  };

  environment.systemPackages = with pkgs; [
    fish
    fishPlugins.done
    fishPlugins.fzf-fish
    fishPlugins.forgit
    fishPlugins.hydro
    fishPlugins.tide
    fishPlugins.pisces
    fishPlugins.colored-man-pages
    fishPlugins.sponge
    fishPlugins.bass
    fishPlugins.foreign-env
    fishPlugins.fzf-fish
    fishPlugins.grc
    fishPlugins.z
    fishPlugins.autopair
    fishPlugins.puffer
    fishPlugins.fishtape
  ];

  # Set fish as an allowed shell
  environment.shells = with pkgs; [ fish ];
}
