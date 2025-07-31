{ config
, lib
, pkgs
, ...
}: {
  services.samba = {
    enable = true;
    nmbd.enable = true;
    winbindd.enable = true;
    openFirewall = true;

    settings = {
      global = {
        workgroup = "WORKGROUP";
        "server role" = "standalone server";
        "netbios name" = "kronos";
        "server string" = "kronos samba";
        security = "user";
        "guest account" = "nobody";
        "map to guest" = "Bad User";
        "name resolve order" = "host bcast";
        "use sendfile" = "yes";
        "min receivefile size" = "16384";
        "aio read size" = "16384";
        "aio write size" = "16384";
        "socket options" = "IPTOS_LOWDELAY TCP_NODELAY IPTOS_THROUGHPUT SO_RCVBUF=131072 SO_SNDBUF=131072";
        "read raw" = "yes";
        "write raw" = "yes";
        "getwd cache" = "yes";
        "oplocks" = "yes";
        "max xmit" = "32768";
        "dead time" = "15";
        "strict locking" = "no";
        "strict sync" = "no";
        "sync always" = "no";
        "large readwrite" = "yes";
        "max open files" = "16384";
        "logging" = "systemd";
        "load printers" = "no";
        "printing" = "bsd";
        "printcap name" = "/dev/null";
        "disable spoolss" = "yes";
        "dos charset" = "CP850";
        "unix charset" = "UTF-8";
        "mangled names" = "no";
        "vfs objects" = "acl_xattr catia fruit streams_xattr";
        "fruit:metadata" = "stream";
        "fruit:model" = "MacSamba";
        "fruit:posix_rename" = "yes";
        "fruit:veto_appledouble" = "no";
        "fruit:wipe_intentionally_left_blank_rfork" = "yes";
        "fruit:delete_empty_adfiles" = "yes";
        "fruit:aapl" = "yes";
      };

      Media = {
        path = "/storage/media";
        browseable = "yes";
        writeable = "yes";
        "create mask" = "0664";
        "directory mask" = "0775";
        "force user" = "amoon";
        "force group" = "media";
        "guest ok" = "yes";
        "veto files" = "/.apdisk/.DS_Store/.TemporaryItems/.Trashes/desktop.ini/ehthumbs.db/Network Trash Folder/Temporary Items/Thumbs.db/";
        "delete veto files" = "yes";
      };

      Backups = {
        path = "/storage/backups";
        browseable = "yes";
        writeable = "yes";
        "valid users" = "amoon";
        "create mask" = "0600";
        "directory mask" = "0700";
        "guest ok" = "no";
      };

      Public = {
        path = "/storage/public";
        browseable = "yes";
        writeable = "yes";
        "guest ok" = "yes";
        "create mask" = "0664";
        "directory mask" = "0775";
        "force user" = "nobody";
        "force group" = "nogroup";
      };
    };
  };

  services.samba-wsdd = {
    enable = true;
    discovery = true;
    openFirewall = true;
  };
}
