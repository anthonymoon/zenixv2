{ config
, lib
, pkgs
, ...
}: {
  imports = [
    ./amoon
    ./root
  ];

  # Define custom groups
  users.groups.media = {
    gid = 993;
  };

  # Default user settings
  users = {
    # Mutable users allows changing passwords
    mutableUsers = true;

    # Default shell for new users
    defaultUserShell = pkgs.bash;
  };
}
