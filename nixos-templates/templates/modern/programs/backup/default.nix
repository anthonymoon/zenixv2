{ config
, lib
, pkgs
, ...
}: {
  environment.systemPackages = with pkgs; [
    # Backup tools
    borgbackup
    restic
    duplicity

    # Cloud sync
    rclone

    # Snapshot tools
    snapper
    timeshift

    # Archive tools
    tar
    zip
    unzip

    # Compression
    gzip
    bzip2
    xz
    zstd
    lz4

    # Deduplication
    duperemove

    # Recovery tools
    ddrescue
    safecopy

    # Disk imaging
    clonezilla
    partclone

    # Incremental backups
    rdiff-backup

    # Version control for configs
    etckeeper
    chezmoi
  ];
}
