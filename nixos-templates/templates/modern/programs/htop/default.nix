{ config
, lib
, pkgs
, ...
}: {
  programs.htop = {
    enable = true;

    settings = {
      # Htop configuration
      show_thread_names = true;
      highlight_base_name = true;
      highlight_megabytes = true;
      tree_view = true;
    };
  };
}
