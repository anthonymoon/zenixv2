{ config
, lib
, pkgs
, ...
}: {
  programs.atuin = {
    enable = true;
    flags = [
      # Add any atuin flags here
    ];
  };
}
