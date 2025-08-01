# ZFS filesystem configuration with partition label support
{
  config,
  lib,
  ...
}: let
  cfg = config.storage.zfs;
in {
  config = lib.mkIf cfg.enable {
    # Configure ZFS to use partition labels for device nodes
    boot.zfs.devNodes = "/dev/disk/by-partlabel";

    # Ensure partition labels are available early in boot
    boot.initrd.postDeviceCommands = lib.mkAfter ''
      # Wait for partition labels to be available
      for i in $(seq 1 10); do
        if [ -e /dev/disk/by-partlabel/disk-main-esp ]; then
          break
        fi
        echo "Waiting for partition labels... ($i/10)"
        sleep 1
      done
    '';

    # Add udev rules to ensure partition labels are created
    services.udev.extraRules = ''
      # Ensure partition labels are available
      KERNEL=="nvme[0-9]n[0-9]p[0-9]", SUBSYSTEM=="block", ENV{ID_PART_ENTRY_NAME}=="disk-main-esp", SYMLINK+="disk/by-partlabel/$env{ID_PART_ENTRY_NAME}"
      KERNEL=="sd[a-z][0-9]", SUBSYSTEM=="block", ENV{ID_PART_ENTRY_NAME}=="disk-main-esp", SYMLINK+="disk/by-partlabel/$env{ID_PART_ENTRY_NAME}"
    '';
  };
}
