# System maintenance automation and optimization
{ config
, lib
, pkgs
, ...
}:
let
  cfg = config.maintenance;
in
{
  options.maintenance = {
    enable = lib.mkEnableOption "automated system maintenance tasks";

    nix = {
      garbageCollect = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enable automatic Nix garbage collection";
        };
        schedule = lib.mkOption {
          type = lib.types.str;
          default = "weekly";
          description = "Garbage collection schedule";
        };
        options = lib.mkOption {
          type = lib.types.str;
          default = "--delete-older-than 14d";
          description = "Garbage collection options";
        };
      };
      optimizeStore = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable Nix store optimization (deduplication)";
      };
    };

    filesystem = {
      trim = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable automatic filesystem trim for SSDs";
      };
      scrub = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable filesystem scrubbing for Btrfs/ZFS";
      };
    };

    logs = {
      cleanup = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable automatic log cleanup";
      };
      maxAge = lib.mkOption {
        type = lib.types.str;
        default = "4weeks";
        description = "Maximum age for system logs";
      };
    };

    updates = {
      database = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable automatic database updates (locate, man)";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # Nix garbage collection
    nix.gc = lib.mkIf cfg.nix.garbageCollect.enable {
      automatic = true;
      dates = cfg.nix.garbageCollect.schedule;
      options = cfg.nix.garbageCollect.options;
      persistent = true; # Run even if system was off during scheduled time
    };

    # Nix store optimization
    nix.optimise = lib.mkIf cfg.nix.optimizeStore {
      automatic = true;
      dates = [ "weekly" ];
    };

    # Filesystem trim for SSDs
    services.fstrim = lib.mkIf cfg.filesystem.trim {
      enable = true;
      interval = "weekly";
    };

    # Btrfs maintenance (if using btrfs)
    systemd.services."btrfs-maintenance" = lib.mkIf (cfg.filesystem.scrub && config.fileSystems."/".fsType == "btrfs") {
      description = "Btrfs filesystem maintenance";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = pkgs.writeShellScript "btrfs-maintenance" ''
          set -euo pipefail

          # Function to log with timestamp
          log() {
            echo "$(date '+%Y-%m-%d %H:%M:%S') [btrfs-maintenance] $*"
          }

          log "Starting Btrfs maintenance..."

          # Get all Btrfs filesystems
          BTRFS_MOUNTS=$(${pkgs.findutils}/bin/find /proc/self/mounts -exec ${pkgs.gnugrep}/bin/grep -E '\sbtrfs\s' {} \; | ${pkgs.gawk}/bin/awk '{print $2}' | sort -u)

          if [ -z "$BTRFS_MOUNTS" ]; then
            log "No Btrfs filesystems found"
            exit 0
          fi

          for mount in $BTRFS_MOUNTS; do
            log "Processing Btrfs filesystem: $mount"

            # Check if it's the first day of the month for scrub
            if [[ $(date +%d) -eq 1 ]]; then
              log "Running monthly scrub on $mount"
              if ${pkgs.btrfs-progs}/bin/btrfs scrub start -B "$mount" 2>/dev/null; then
                log "Scrub completed successfully on $mount"
              else
                log "Warning: Scrub failed on $mount"
              fi
            fi

            # Weekly balance with usage filters to avoid unnecessary work
            log "Running balance on $mount"
            if ${pkgs.btrfs-progs}/bin/btrfs balance start -dusage=50 -musage=50 "$mount" 2>/dev/null; then
              log "Balance completed on $mount"
            else
              log "Warning: Balance failed on $mount (this may be normal if already balanced)"
            fi

            # Defragment specific directories that benefit from it
            for dir in "$mount/var/log" "$mount/var/cache"; do
              if [ -d "$dir" ]; then
                log "Defragmenting $dir"
                ${pkgs.btrfs-progs}/bin/btrfs filesystem defragment -r -czstd "$dir" 2>/dev/null || log "Warning: Defragmentation failed for $dir"
              fi
            done
          done

          # Global trim operation
          log "Running fstrim on all mounted filesystems"
          ${pkgs.util-linux}/bin/fstrim -av 2>/dev/null || log "Warning: Some fstrim operations failed"

          log "Btrfs maintenance completed"
        '';
      };
    };

    systemd.timers."btrfs-maintenance" = lib.mkIf (cfg.filesystem.scrub && config.fileSystems."/".fsType == "btrfs") {
      description = "Btrfs maintenance timer";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "weekly";
        Persistent = true;
        RandomizedDelaySec = "1h"; # Randomize start time to avoid load spikes
      };
    };

    # ZFS maintenance (if using zfs)
    services.zfs = lib.mkIf (cfg.filesystem.scrub && builtins.elem "zfs" (config.boot.supportedFilesystems or [ ])) {
      autoScrub = {
        enable = true;
        interval = "monthly";
        pools = [ ]; # Empty means all pools
      };
      autoSnapshot = {
        enable = true;
        frequent = 4; # Keep 4 15-minute snapshots
        hourly = 24; # Keep 24 hourly snapshots
        daily = 7; # Keep 7 daily snapshots
        weekly = 4; # Keep 4 weekly snapshots
        monthly = 12; # Keep 12 monthly snapshots
      };
      trim = {
        enable = true;
        interval = "weekly";
      };
    };

    # ZFS additional maintenance
    systemd.services."zfs-maintenance" = lib.mkIf (cfg.filesystem.scrub && builtins.elem "zfs" (config.boot.supportedFilesystems or [ ])) {
      description = "ZFS maintenance tasks";
      after = [ "zfs.target" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = pkgs.writeShellScript "zfs-maintenance" ''
          set -euo pipefail

          # Function to log with timestamp
          log() {
            echo "$(date '+%Y-%m-%d %H:%M:%S') [zfs-maintenance] $*"
          }

          log "Starting ZFS maintenance..."

          # Check if ZFS is available
          if ! command -v zpool >/dev/null 2>&1; then
            log "ZFS not available, skipping maintenance"
            exit 0
          fi

          # Get all ZFS pools
          POOLS=$(${pkgs.zfs}/bin/zpool list -H -o name 2>/dev/null || true)

          if [ -z "$POOLS" ]; then
            log "No ZFS pools found"
            exit 0
          fi

          # Monitor pool health
          log "Checking ZFS pool health..."
          for pool in $POOLS; do
            status=$(${pkgs.zfs}/bin/zpool status -x "$pool" 2>/dev/null || echo "ERROR")
            if [ "$status" != "all pools are healthy" ] && [ "$status" != "ERROR" ]; then
              log "Warning: Pool $pool status: $status"
            else
              log "Pool $pool is healthy"
            fi
          done

          # Clean up old snapshots beyond retention policy (keep manual ones)
          log "Cleaning old automatic snapshots..."
          ${pkgs.zfs}/bin/zfs list -H -o name -t snapshot | ${pkgs.gnugrep}/bin/grep '@zfs-auto-snap' | while read snap; do
            # Get snapshot creation time
            creation=$(${pkgs.zfs}/bin/zfs get -H -o value creation "$snap" 2>/dev/null || continue)

            # Convert to timestamp and check if older than 1 year
            if command -v date >/dev/null 2>&1; then
              created_ts=$(date -d "$creation" +%s 2>/dev/null || continue)
              current_ts=$(date +%s)
              age_days=$(( (current_ts - created_ts) / 86400 ))

              if [ "$age_days" -gt 365 ]; then
                log "Removing old snapshot: $snap (age: $age_days days)"
                ${pkgs.zfs}/bin/zfs destroy "$snap" 2>/dev/null || log "Warning: Failed to destroy $snap"
              fi
            fi
          done

          # Export pool statistics for monitoring
          for pool in $POOLS; do
            log "Pool $pool statistics:"
            ${pkgs.zfs}/bin/zpool iostat -v "$pool" | head -20
          done

          # Check and optimize dedup tables if enabled
          for pool in $POOLS; do
            dedup_ratio=$(${pkgs.zfs}/bin/zpool list -H -o dedupratio "$pool" 2>/dev/null || echo "1.00x")
            if [ "$dedup_ratio" != "1.00x" ]; then
              log "Pool $pool has deduplication enabled (ratio: $dedup_ratio)"
              # You might want to add dedup table optimization here
            fi
          done

          log "ZFS maintenance completed"
        '';
      };
    };

    systemd.timers."zfs-maintenance" = lib.mkIf (cfg.filesystem.scrub && builtins.elem "zfs" (config.boot.supportedFilesystems or [ ])) {
      description = "ZFS maintenance timer";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "weekly";
        Persistent = true;
        RandomizedDelaySec = "2h";
      };
    };

    # System log cleanup
    systemd.services."log-cleanup" = lib.mkIf cfg.logs.cleanup {
      description = "System log cleanup";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = pkgs.writeShellScript "log-cleanup" ''
          set -euo pipefail

          # Function to log with timestamp
          log() {
            echo "$(date '+%Y-%m-%d %H:%M:%S') [log-cleanup] $*"
          }

          log "Starting log cleanup..."

          # Clean systemd journal
          log "Cleaning systemd journal (keeping ${cfg.logs.maxAge})"
          ${pkgs.systemd}/bin/journalctl --vacuum-time=${cfg.logs.maxAge} || log "Warning: Journal cleanup failed"

          # Clean old log files
          log "Cleaning old log files in /var/log"
          ${pkgs.findutils}/bin/find /var/log -type f -name "*.log.*" -mtime +30 -delete 2>/dev/null || true
          ${pkgs.findutils}/bin/find /var/log -type f -name "*.gz" -mtime +30 -delete 2>/dev/null || true
          ${pkgs.findutils}/bin/find /var/log -type f -name "*.old" -mtime +30 -delete 2>/dev/null || true

          # Clean temporary files
          log "Cleaning temporary files"
          ${pkgs.systemd}/bin/systemd-tmpfiles --clean || log "Warning: tmpfiles cleanup failed"

          # Clean package manager cache
          if [ -d /var/cache/nix ]; then
            log "Cleaning Nix cache"
            ${pkgs.findutils}/bin/find /var/cache/nix -type f -mtime +7 -delete 2>/dev/null || true
          fi

          # Clean user caches (be careful with this)
          for user_home in /home/*; do
            if [ -d "$user_home/.cache" ]; then
              user=$(basename "$user_home")
              log "Cleaning cache for user: $user"
              ${pkgs.findutils}/bin/find "$user_home/.cache" -type f -mtime +30 -delete 2>/dev/null || true
            fi
          done

          log "Log cleanup completed"
        '';
      };
    };

    systemd.timers."log-cleanup" = lib.mkIf cfg.logs.cleanup {
      description = "Log cleanup timer";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "weekly";
        Persistent = true;
        RandomizedDelaySec = "30m";
      };
    };

    # Database updates (locate, man, etc.)
    systemd.services."system-database-update" = lib.mkIf cfg.updates.database {
      description = "System database updates";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = pkgs.writeShellScript "system-database-update" ''
          set -euo pipefail

          # Function to log with timestamp
          log() {
            echo "$(date '+%Y-%m-%d %H:%M:%S') [database-update] $*"
          }

          log "Starting database updates..."

          # Update locate database
          if command -v updatedb >/dev/null 2>&1; then
            log "Updating locate database"
            ${pkgs.findutils}/bin/updatedb || log "Warning: updatedb failed"
          fi

          # Update man database
          if command -v mandb >/dev/null 2>&1; then
            log "Updating man database"
            ${pkgs.man-db}/bin/mandb -q || log "Warning: mandb failed"
          fi

          # Update font cache
          if command -v fc-cache >/dev/null 2>&1; then
            log "Updating font cache"
            ${pkgs.fontconfig}/bin/fc-cache -f || log "Warning: fc-cache failed"
          fi

          # Update desktop database
          if command -v update-desktop-database >/dev/null 2>&1; then
            log "Updating desktop database"
            ${pkgs.desktop-file-utils}/bin/update-desktop-database || log "Warning: desktop database update failed"
          fi

          # Update MIME database
          if command -v update-mime-database >/dev/null 2>&1; then
            log "Updating MIME database"
            ${pkgs.shared-mime-info}/bin/update-mime-database /usr/share/mime || log "Warning: MIME database update failed"
          fi

          log "Database updates completed"
        '';
      };
    };

    systemd.timers."system-database-update" = lib.mkIf cfg.updates.database {
      description = "System database update timer";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "weekly";
        Persistent = true;
        RandomizedDelaySec = "1h";
      };
    };

    # Performance monitoring and alerting
    systemd.services."performance-monitor" = {
      description = "System performance monitoring";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = pkgs.writeShellScript "performance-monitor" ''
          set -euo pipefail

          # Function to log with timestamp
          log() {
            echo "$(date '+%Y-%m-%d %H:%M:%S') [perf-monitor] $*"
          }

          log "Starting performance monitoring..."

          # Check disk space
          df -h | while read line; do
            if echo "$line" | ${pkgs.gnugrep}/bin/grep -E ' 9[0-9]%| 100%' >/dev/null; then
              log "Warning: High disk usage detected: $line"
            fi
          done

          # Check memory usage
          mem_usage=$(free | ${pkgs.gawk}/bin/awk '/^Mem:/{printf("%.1f", $3/$2 * 100)}')
          if [ "$(echo "$mem_usage > 90" | ${pkgs.bc}/bin/bc -l)" = "1" ]; then
            log "Warning: High memory usage: $mem_usage%"
          fi

          # Check CPU load
          load_avg=$(uptime | ${pkgs.gawk}/bin/awk -F'load average:' '{print $2}' | ${pkgs.gawk}/bin/awk '{print $1}' | ${pkgs.gnused}/bin/sed 's/,//')
          cpu_count=$(nproc)
          if [ "$(echo "$load_avg > $cpu_count * 2" | ${pkgs.bc}/bin/bc -l)" = "1" ]; then
            log "Warning: High CPU load: $load_avg (CPUs: $cpu_count)"
          fi

          # Check for failed systemd services
          failed_services=$(${pkgs.systemd}/bin/systemctl --failed --no-legend | wc -l)
          if [ "$failed_services" -gt 0 ]; then
            log "Warning: $failed_services failed systemd services detected"
            ${pkgs.systemd}/bin/systemctl --failed --no-legend | while read service; do
              log "Failed service: $service"
            done
          fi

          # Check SMART health for all drives
          for drive in /dev/sd? /dev/nvme?n?; do
            if [ -b "$drive" ]; then
              smart_status=$(${pkgs.smartmontools}/bin/smartctl -H "$drive" 2>/dev/null | ${pkgs.gnugrep}/bin/grep "SMART overall-health" | ${pkgs.gawk}/bin/awk '{print $NF}' || echo "UNKNOWN")
              if [ "$smart_status" != "PASSED" ]; then
                log "Warning: SMART health check failed for $drive: $smart_status"
              fi
            fi
          done

          log "Performance monitoring completed"
        '';
      };
    };

    systemd.timers."performance-monitor" = {
      description = "Performance monitoring timer";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "daily";
        Persistent = true;
        RandomizedDelaySec = "1h";
      };
    };
  };
}
