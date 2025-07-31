# NixOS Ephemeral Root ZFS System Architecture

## System Overview

This architecture implements an ephemeral root filesystem using ZFS snapshots, where the root filesystem is reset on every boot while preserving essential data in persistent datasets.

## Core Design Principles

1. **Ephemeral Root**: Root filesystem (`/`) resets to a clean state on every boot
2. **Explicit Persistence**: Only explicitly defined paths survive reboots
3. **Declarative Configuration**: All system state defined in Nix flake
4. **Atomic Operations**: ZFS snapshots ensure consistent rollback

## Component Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     NixOS Boot Process                       │
├─────────────────────────────────────────────────────────────┤
│  1. systemd-boot → 2. initrd → 3. ZFS rollback → 4. Mount  │
└─────────────────────────────────────────────────────────────┘
                                ↓
┌─────────────────────────────────────────────────────────────┐
│                    Filesystem Layout                         │
├─────────────────────────────────────────────────────────────┤
│  ESP (2GB)                    → /boot                       │
│  rpool/nixos/empty@start      → / (ephemeral)              │
│  rpool/nixos/nix              → /nix                       │
│  rpool/nixos/home             → /home                      │
│  rpool/nixos/persist          → /persist                   │
│  └── /persist/etc/nixos       → /etc/nixos (bind mount)    │
│  └── /persist/etc/ssh         → /etc/ssh (symlink)         │
│  └── /persist/var/log         → /var/log (bind mount)      │
│  └── /persist/var/lib         → /var/lib (bind mount)      │
│  rpool/docker (zvol)          → Docker storage             │
└─────────────────────────────────────────────────────────────┘
```

## ZFS Dataset Structure

```
rpool                          # Root pool
├── nixos                      # NixOS datasets
│   ├── empty                  # Ephemeral root (snapshot: @start)
│   ├── nix                    # Nix store (persistent)
│   ├── home                   # User data (persistent)
│   └── persist                # System state (persistent)
└── docker                     # Docker zvol (50GB)
```

## Boot Sequence

1. **UEFI/BIOS** → systemd-boot
2. **systemd-boot** → Loads kernel and initrd
3. **initrd** → Executes ZFS rollback service
4. **ZFS Rollback** → `zfs rollback -r rpool/nixos/empty@start`
5. **Mount** → Mount persistent datasets
6. **systemd** → Normal boot continues

## Persistence Strategy

### Persistent Paths
- `/nix` - Nix store and profiles
- `/home` - User home directories
- `/persist/etc/nixos` - System configuration
- `/persist/etc/ssh` - SSH host keys
- `/persist/var/log` - System logs
- `/persist/var/lib` - Application state
- `/persist/etc/machine-id` - Machine ID

### Ephemeral Paths
- `/` - Root filesystem
- `/tmp` - Temporary files
- `/var/tmp` - Temporary variable data
- `/etc` - System configuration (except persisted)

## Security Considerations

1. **Clean State**: Every boot starts from known-good state
2. **Reduced Attack Surface**: Malware cannot persist in root
3. **Secrets Management**: SSH keys and sensitive data in persistent storage
4. **Audit Trail**: Logs preserved across reboots

## Performance Optimization

- **LZ4 Compression**: Fast compression for all datasets
- **noatime**: Disabled access time updates on /nix
- **10% Reserved Space**: Prevents ZFS performance degradation
- **Optimized ARC**: Tuned for system memory

## Disaster Recovery

1. **Snapshot Recovery**: Boot from previous root snapshots if needed
2. **Configuration Rollback**: Previous generations in /nix/var/nix/profiles
3. **Data Backup**: Regular snapshots of persistent datasets
4. **Remote Replication**: Optional ZFS send/receive for off-site backup