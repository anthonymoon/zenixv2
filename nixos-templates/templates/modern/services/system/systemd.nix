{ config
, lib
, pkgs
, ...
}: {
  # Systemd timers
  systemd.timers."xidlehook-caffeine" = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "*-*-* *:*:00";
      Unit = "xidlehook-caffeine.service";
    };
  };

  systemd.services."xidlehook-caffeine" = {
    script = ''
      echo "Running xidlehook caffeine check..."
    '';
    serviceConfig = {
      Type = "oneshot";
      User = "amoon";
    };
  };

  # Systemd service overrides
  systemd.services.nix-daemon.serviceConfig = {
    LimitNOFILE = 1048576;
    LimitNOFILESoft = 1048576;
  };

  # TimeSync service
  services.timesyncd.enable = true;

  # Fwupd service
  services.fwupd.enable = true;

  # Fstrim service
  services.fstrim.enable = true;

  # Printing service
  services.printing.enable = lib.mkDefault true;

  # LLDP service
  services.lldpd.enable = true;

  # Nix serve
  services.nix-serve = {
    enable = true;
    secretKeyFile = "/var/keys/cache-priv-key.pem";
    port = 5000;
  };
}
