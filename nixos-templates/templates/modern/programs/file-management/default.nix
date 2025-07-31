{ config
, lib
, pkgs
, ...
}: {
  environment.systemPackages = with pkgs; [
    # File search
    fd
    findutils
    mlocate

    # Text search
    ripgrep
    silver-searcher
    ack

    # File browsers
    mc
    ranger
    nnn
    lf

    # Fuzzy finders
    fzf
    skim

    # File comparison
    diff-so-fancy
    delta
    meld

    # File synchronization
    rsync
    rclone
    unison

    # Archiving
    atool

    # File organization
    rename
    mmv

    # File analysis
    file
    binwalk

    # File recovery
    testdisk
    photorec
    extundelete

    # Directory navigation
    z
    autojump
    zoxide

    # File preview
    bat
    hexyl

    # Duplicate finding
    fdupes
    rdfind
  ];
}
