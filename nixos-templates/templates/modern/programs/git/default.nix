{ config
, lib
, pkgs
, ...
}: {
  programs.git = {
    enable = true;
    package = pkgs.git;

    config = {
      init.defaultBranch = "main";

      # Add global git config here
      # user.name = "Your Name";
      # user.email = "your@email.com";
    };

    # Enable git-lfs
    lfs.enable = true;
  };
}
