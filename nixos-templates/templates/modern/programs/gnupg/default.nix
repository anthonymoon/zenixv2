{ config
, lib
, pkgs
, ...
}: {
  programs.gnupg = {
    agent = {
      enable = true;
      enableSSHSupport = true;
      pinentryFlavor = "curses";
    };
  };

  # Additional GnuPG packages
  environment.systemPackages = with pkgs; [
    gnupg
    pinentry-curses
  ];
}
