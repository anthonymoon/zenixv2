# ZFS Memory Optimization Guide

## Overview

This guide explains how to reduce ZFS RAM usage from 19-21GB down to 4-5GB while maintaining good performance.

## Default vs Optimized Memory Usage

### Default Configuration (32GB System)
- **ARC**: 16GB (50% of RAM)
- **Dedup Tables**: 3-5GB
- **Total ZFS**: ~19-21GB
- **Available for Apps**: ~11-13GB

### Optimized Configuration (32GB System)
- **ARC**: 4GB (12.5% of RAM)
- **Dedup**: Disabled (0GB)
- **Total ZFS**: ~4-5GB
- **Available for Apps**: ~27-28GB

## Key Optimizations

### 1. Disable Deduplication

Deduplication is disabled on all datasets. Instead, we rely on compression for space savings:

```nix
# In disko.nix - all datasets now have:
dedup = "off";
```

**Impact**: Saves 3-5GB RAM, ~10-20% more disk usage

### 2. Limit ARC Size

Reduce ARC from 50% to 12.5% of system RAM:

```nix
boot.kernelParams = [
  "zfs.zfs_arc_max=4294967296"  # 4GB max
  "zfs.zfs_arc_min=1073741824"  # 1GB min
];
```

**Impact**: Frees 12GB RAM, slightly slower file access for cold data

### 3. Aggressive Memory Reclaim

Configure kernel to reclaim ARC memory more aggressively:

```nix
boot.kernel.sysctl = {
  "vm.vfs_cache_pressure" = 200;  # More aggressive cache reclaim
  "vm.swappiness" = 1;             # Minimize swapping
};
```

### 4. Disable Prefetching

Reduce speculative reads that consume memory:

```nix
boot.extraModprobeConfig = ''
  options zfs zfs_prefetch_disable=1
  options zfs l2arc_noprefetch=1
'';
```

## Performance Trade-offs

### What You Lose
- **Deduplication**: No automatic duplicate file detection
- **Large ARC**: Less filesystem caching, more disk reads
- **Prefetching**: Slightly slower sequential reads

### What You Keep
- **Compression**: Still get 2-3x space savings with ZStandard
- **Fast Writes**: Optimized recordsizes maintained
- **Data Integrity**: All ZFS data protection features active
- **Snapshots**: Can still use if needed (manually)

## Monitoring Memory Usage

Check current ZFS memory usage:

```bash
# Total ARC size
arc_summary | grep -E "ARC Size|Memory"

# Detailed stats
cat /proc/spl/kstat/zfs/arcstats | grep size

# System memory
free -h
```

## When to Use This Configuration

✅ **Good for:**
- Gaming systems (more RAM for games)
- Development workstations (more RAM for builds)
- Systems with <32GB RAM
- Mixed workloads with memory-hungry applications

❌ **Not ideal for:**
- File servers with lots of duplicate data
- Systems with >64GB RAM
- Pure NAS/storage servers
- Workloads with many small random reads

## Re-enabling Features

If you have more RAM or different needs:

```bash
# Re-enable deduplication (per dataset)
sudo zfs set dedup=on rpool/home

# Increase ARC (requires reboot)
# Edit /etc/nixos/configuration.nix and remove kernelParams

# Check dedup effectiveness
zpool status -D
```

## Recommended Configurations by RAM

### 16GB System
```nix
"zfs.zfs_arc_max=2147483648"  # 2GB
```

### 32GB System (default)
```nix
"zfs.zfs_arc_max=4294967296"  # 4GB
```

### 64GB System
```nix
"zfs.zfs_arc_max=8589934592"  # 8GB
```

### 128GB+ System
```nix
# Remove limits, let ZFS auto-tune
```

## Space Savings Without Dedup

Even without deduplication, ZFS provides excellent space efficiency:

1. **Compression** (2-3x typical):
   - Text files: 5-10x
   - Code: 3-5x
   - Binaries: 1.5-2x
   
2. **Snapshots** (minimal overhead):
   - Only changed blocks consume space
   - Can manually snapshot before major changes

3. **Reflinks** (for supported applications):
   - Copy-on-write file clones
   - Instant copies with no space usage

## Summary

This optimized configuration frees up 16GB of RAM (on a 32GB system) for applications while maintaining good ZFS performance for desktop/workstation use. The trade-off is slightly higher disk usage and occasional cache misses, but for gaming and development workloads, having more application memory is usually more valuable than filesystem caching.