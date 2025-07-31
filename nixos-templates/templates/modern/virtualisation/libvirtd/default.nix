{ config
, lib
, pkgs
, ...
}: {
  virtualisation.libvirtd = {
    enable = true;
    onBoot = "ignore";
    onShutdown = "shutdown";
    qemu = {
      package = pkgs.qemu_kvm;
      runAsRoot = false;
      swtpm.enable = true;
      ovmf = {
        enable = true;
        packages = [ pkgs.OVMFFull.fd ];
      };
      verbatimConfig = ''
        user = "amoon"
        group = "libvirtd"
        dynamic_ownership = 1
        remember_owner = 1
        namespaces = []
        clear_emulator_capabilities = 0
        relaxed_acs_check = 1
        cgroup_device_acl = [
          "/dev/null", "/dev/full", "/dev/zero",
          "/dev/random", "/dev/urandom",
          "/dev/ptmx", "/dev/kvm",
          "/dev/rtc", "/dev/hpet",
          "/dev/vfio/vfio", "/dev/vfio/1",
          "/dev/vfio/2", "/dev/vfio/3",
          "/dev/vfio/4", "/dev/vfio/5"
        ]
      '';
    };
    extraOptions = [
      "--verbose"
    ];
    extraConfig = ''
      unix_sock_group = "libvirtd"
      unix_sock_ro_perms = "0770"
      unix_sock_rw_perms = "0770"
      auth_unix_ro = "none"
      auth_unix_rw = "none"
      log_filters = "3:qemu 3:libvirt 4:object 4:json 4:event 1:util"
      log_outputs = "2:stderr"
    '';
  };
}
