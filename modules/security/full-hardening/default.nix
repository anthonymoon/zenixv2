# Full security hardening
{
  config,
  lib,
  pkgs,
  ...
}:

{
  imports = [
    ../hardening
  ];

  # Maximum kernel hardening
  boot.kernel.sysctl = {
    # Kernel hardening
    "kernel.kptr_restrict" = 2;
    "kernel.dmesg_restrict" = 1;
    "kernel.printk" = "3 3 3 3";
    "kernel.unprivileged_bpf_disabled" = 1;
    "kernel.yama.ptrace_scope" = 3;
    "net.core.bpf_jit_harden" = 2;
    "dev.tty.ldisc_autoload" = 0;
    "vm.unprivileged_userfaultfd" = 0;
    "kernel.kexec_load_disabled" = 1;
    "kernel.sysrq" = 0;
    "kernel.ftrace_enabled" = false;

    # Network hardening
    "net.ipv4.tcp_syncookies" = 1;
    "net.ipv4.tcp_rfc1337" = 1;
    "net.ipv4.conf.all.rp_filter" = 1;
    "net.ipv4.conf.default.rp_filter" = 1;
    "net.ipv4.conf.all.accept_redirects" = 0;
    "net.ipv4.conf.default.accept_redirects" = 0;
    "net.ipv4.conf.all.secure_redirects" = 0;
    "net.ipv4.conf.default.secure_redirects" = 0;
    "net.ipv6.conf.all.accept_redirects" = 0;
    "net.ipv6.conf.default.accept_redirects" = 0;
    "net.ipv4.conf.all.send_redirects" = 0;
    "net.ipv4.conf.all.accept_source_route" = 0;
    "net.ipv6.conf.all.accept_source_route" = 0;
    "net.ipv6.conf.all.accept_ra" = 0;
    "net.ipv6.conf.default.accept_ra" = 0;
    "net.ipv4.tcp_sack" = 0;
    "net.ipv4.tcp_dsack" = 0;
    "net.ipv4.tcp_fack" = 0;
  };

  # Security modules
  security = {
    lockKernelModules = true;
    protectKernelImage = true;
    allowSimultaneousMultithreading = false;
    forcePageTableIsolation = true;
    virtualisation.flushL1DataCache = "always";

    apparmor.enable = true;
    apparmor.killUnconfinedConfinables = true;

    audit.enable = true;
    auditd.enable = true;
  };

  # Additional hardening
  boot.kernelParams = [
    "page_alloc.shuffle=1"
    "slab_nomerge"
    "vsyscall=none"
    "debugfs=off"
    "oops=panic"
    "module.sig_enforce=1"
    "lockdown=confidentiality"
    "mce=0"
    "quiet"
    "loglevel=0"
  ];

  # More kernel modules to blacklist
  boot.blacklistedKernelModules = [
    # Networking
    "dccp"
    "sctp"
    "rds"
    "tipc"
    "n-hdlc"
    "ax25"
    "netrom"
    "x25"
    "rose"
    "decnet"
    "econet"
    "af_802154"
    "ipx"
    "appletalk"
    "psnap"
    "p8023"
    "p8022"
    "can"
    "atm"

    # Filesystems
    "cramfs"
    "freevxfs"
    "jffs2"
    "hfs"
    "hfsplus"
    "squashfs"
    "udf"
    "cifs"
    "nfs"
    "nfsv3"
    "nfsv4"
    "gfs2"

    # Misc
    "vivid"
    "bluetooth"
    "btusb"
    "uvcvideo"
    "firewire-core"
  ];

  # Disable coredumps
  systemd.coredump.enable = false;
  security.pam.loginLimits = [
    {
      domain = "*";
      item = "core";
      type = "hard";
      value = "0";
    }
  ];

  # Hide processes
  security.hideProcessInformation = true;

  # Disable root
  users.users.root.hashedPassword = "!";

  # Only allow wheel group to use nix
  nix.settings.allowed-users = [ "@wheel" ];
}
