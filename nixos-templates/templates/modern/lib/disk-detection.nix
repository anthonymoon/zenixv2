{ lib
, pkgs
, ...
}: rec {
  # Helper function to try evaluation with fallback
  try = expr: fallback:
    let
      result = builtins.tryEval expr;
    in
    if result.success
    then result.value
    else fallback;
  # Get disk information using lsblk
  getDiskInfo = disk:
    let
      # Ensure we're working with the actual device path
      realDisk =
        if lib.hasPrefix "/dev/disk/by-id/" disk
        then builtins.readLink disk
        else disk;

      # Extract just the device name for lsblk
      deviceName = builtins.baseNameOf realDisk;
    in
    builtins.fromJSON (
      builtins.readFile (
        pkgs.runCommand "disk-info-${deviceName}"
          {
            buildInputs = [ pkgs.util-linux pkgs.jq ];
          } ''
          # Check if device exists first
          if [[ ! -b "/dev/${deviceName}" ]]; then
            echo '{"error": "Device not found", "name": "${deviceName}"}' > $out
            exit 0
          fi

          # Get disk information
          ${pkgs.util-linux}/bin/lsblk -J -b -o NAME,SIZE,TYPE,TRAN,ROTA,MODEL,SERIAL,MOUNTPOINT "/dev/${deviceName}" 2>/dev/null || \
            echo '{"error": "Failed to read device", "name": "${deviceName}"}' > $out
        ''
      )
    );

  # Get all available disks from /dev/disk/by-id
  getAllDisks =
    { excludeRemovable ? true
    , excludeLoop ? true
    , excludePartitions ? true
    , excludeOptical ? true
    ,
    }:
    let
      # Read all symlinks from /dev/disk/by-id
      byIdPath = "/dev/disk/by-id";
      allEntries =
        if builtins.pathExists byIdPath
        then builtins.readDir byIdPath
        else { };

      # Filter to only symlinks (actual devices)
      diskEntries = lib.filterAttrs (name: type: type == "symlink") allEntries;

      # Convert to full paths
      diskPaths = lib.mapAttrsToList (name: _: "${byIdPath}/${name}") diskEntries;

      # Apply filters
      filteredDisks =
        builtins.filter
          (
            disk:
            let
              name = builtins.baseNameOf disk;
            in
            # Exclude partitions (contain -part or end with numbers)
            (!excludePartitions || !(lib.hasInfix "-part" name || builtins.match ".*[0-9]$" name != null))
            &&
            # Exclude loop devices
            (!excludeLoop || !lib.hasPrefix "loop-" name)
            &&
            # Exclude optical drives
            (!excludeOptical || !(lib.hasInfix "cd" name || lib.hasInfix "dvd" name || lib.hasInfix "bd" name))
            &&
            # Additional checks for removable devices would require runtime detection
            true
          )
          diskPaths;
    in
    filteredDisks;

  # Check if a disk is removable (runtime check)
  isRemovable = disk:
    let
      devicePath =
        if lib.hasPrefix "/dev/disk/by-id/" disk
        then builtins.readLink disk
        else disk;
      deviceName = builtins.baseNameOf devicePath;
      sysPath = "/sys/block/${deviceName}/removable";
    in
    builtins.pathExists sysPath
    && (builtins.readFile sysPath) == "1\n";

  # Filter disks based on criteria
  filterDisks =
    { disks ? getAllDisks { }
    , minSizeGB ? 20
    , maxSizeGB ? null
    , transport ? null
    , # "nvme", "sata", "usb", etc.
      rotational ? null
    , # true for HDD, false for SSD
      model ? null
    , # regex pattern for model matching
      excludeDisks ? [ ]
    , # List of disks to exclude
    }:
    builtins.filter
      (
        disk:
        let
          info = getDiskInfo disk;
          hasError = info ? error;

          # Skip if we can't get disk info
          validDisk = !hasError && info ? blockdevices && builtins.length info.blockdevices > 0;

          diskData =
            if validDisk
            then builtins.head info.blockdevices
            else { };

          sizeBytes =
            if diskData ? size
            then diskData.size
            else 0;
          sizeGB = sizeBytes / (1024 * 1024 * 1024);

          # Check exclusion list
          notExcluded = !builtins.elem disk excludeDisks;
        in
        validDisk
        && notExcluded
        && (minSizeGB == null || sizeGB >= minSizeGB)
        && (maxSizeGB == null || sizeGB <= maxSizeGB)
        && (transport == null || (diskData ? tran && diskData.tran == transport))
        && (rotational
        == null
        || (diskData ? rota
        && (
          if rotational
          then diskData.rota == "1"
          else diskData.rota == "0"
        )))
        && (model == null || (diskData ? model && builtins.match model diskData.model != null))
      )
      disks;

  # Smart primary disk detection with scoring
  detectPrimaryDisk =
    args @ { preferNvme ? true
    , preferSSD ? true
    , minSizeGB ? 20
    , excludeDisks ? [ ]
    , fallbackToAny ? true
    , ...
    }:
    let
      candidateDisks = filterDisks args;

      # Score each disk based on preferences
      scoreDisk = disk:
        let
          info = getDiskInfo disk;
          hasError = info ? error;

          # Default score for invalid disks
          validDisk = !hasError && info ? blockdevices && builtins.length info.blockdevices > 0;

          diskData =
            if validDisk
            then builtins.head info.blockdevices
            else { };

          # Transport type scoring
          isNvme = diskData ? tran && diskData.tran == "nvme";
          isSata = diskData ? tran && diskData.tran == "sata";

          # Rotation scoring (SSD vs HDD)
          isSSD = diskData ? rota && diskData.rota == "0";
          isHDD = diskData ? rota && diskData.rota == "1";

          # Size scoring (prefer larger disks, but not excessively)
          sizeBytes =
            if diskData ? size
            then diskData.size
            else 0;
          sizeGB = sizeBytes / (1024 * 1024 * 1024);
          sizeScore =
            if sizeGB > 0
            then builtins.min (sizeGB / 100) 10
            else 0;

          # Calculate total score
          score =
            (
              if !validDisk
              then -1000
              else 0
            )
            + (
              if preferNvme && isNvme
              then 1000
              else 0
            )
            + (
              if preferSSD && isSSD
              then 500
              else 0
            )
            + (
              if isSata && isSSD
              then 300
              else 0
            )
            + # SATA SSD is good but not as good as NVMe
            (
              if isHDD
              then -200
              else 0
            )
            + # Penalize HDDs
            sizeScore;
        in
        { inherit disk score; };

      # Score all disks and sort by score
      scoredDisks = map scoreDisk candidateDisks;
      sortedDisks = lib.sort (a: b: a.score > b.score) scoredDisks;

      # Get the best disk
      bestDisk =
        if builtins.length sortedDisks > 0
        then (builtins.head sortedDisks).disk
        else null;
    in
    if bestDisk != null
    then bestDisk
    else if fallbackToAny
    then
    # Try to get any disk if no good candidates
      let
        allDisks = getAllDisks { };
      in
      if builtins.length allDisks > 0
      then builtins.head allDisks
      else throw "No suitable disk found with criteria: ${builtins.toJSON args}"
    else throw "No suitable disk found with criteria: ${builtins.toJSON args}";

  # Detect matching disks for RAID configurations
  detectMatchingDisks =
    { count ? 2
    , sizeTolerancePercent ? 5
    , preferSameModel ? true
    , ...
    } @ args:
    let
      allDisks = filterDisks (removeAttrs args [ "count" "sizeTolerancePercent" "preferSameModel" ]);

      # Get disk information for all candidates
      diskInfos =
        map
          (disk: {
            inherit disk;
            info = getDiskInfo disk;
          })
          allDisks;

      # Group disks by approximate size
      groupBySimilarSize = disks:
        let
          # Calculate size groups with tolerance
          getGroupKey = diskInfo:
            let
              hasError = diskInfo.info ? error;
              validDisk = !hasError && diskInfo.info ? blockdevices && builtins.length diskInfo.info.blockdevices > 0;

              diskData =
                if validDisk
                then builtins.head diskInfo.info.blockdevices
                else { };
              sizeBytes =
                if diskData ? size
                then diskData.size
                else 0;
              sizeGB = sizeBytes / (1024 * 1024 * 1024);

              # Round to tolerance groups (e.g., 5% tolerance)
              toleranceGB = sizeGB * sizeTolerancePercent / 100;
              groupSize = builtins.max 10 toleranceGB; # Minimum 10GB groups
              groupKey = toString (builtins.floor (sizeGB / groupSize) * groupSize);
            in
            if validDisk
            then groupKey
            else "invalid";

          # Group by size key
          grouped = lib.groupBy getGroupKey disks;
        in
        # Remove invalid disks group
        removeAttrs grouped [ "invalid" ];

      sizeGroups = groupBySimilarSize diskInfos;

      # Find the best group with enough disks
      findBestGroup = groups:
        let
          # Score each group
          scoreGroup = groupDisks:
            let
              groupSize = builtins.length groupDisks;
              hasEnoughDisks = groupSize >= count;

              # Prefer groups with NVMe disks
              nvmeCount = builtins.length (builtins.filter
                (
                  d:
                  let
                    hasError = d.info ? error;
                    validDisk = !hasError && d.info ? blockdevices && builtins.length d.info.blockdevices > 0;
                    diskData =
                      if validDisk
                      then builtins.head d.info.blockdevices
                      else { };
                  in
                  validDisk && diskData ? tran && diskData.tran == "nvme"
                )
                groupDisks);

              # Prefer groups with SSDs
              ssdCount = builtins.length (builtins.filter
                (
                  d:
                  let
                    hasError = d.info ? error;
                    validDisk = !hasError && d.info ? blockdevices && builtins.length d.info.blockdevices > 0;
                    diskData =
                      if validDisk
                      then builtins.head d.info.blockdevices
                      else { };
                  in
                  validDisk && diskData ? rota && diskData.rota == "0"
                )
                groupDisks);

              score =
                (
                  if hasEnoughDisks
                  then 1000
                  else 0
                )
                + (nvmeCount * 100)
                + (ssdCount * 50)
                + groupSize;
            in
            { inherit groupDisks score; };

          scoredGroups = lib.mapAttrsToList (key: disks: scoreGroup disks) groups;
          sortedGroups = lib.sort (a: b: a.score > b.score) scoredGroups;
        in
        if builtins.length sortedGroups > 0
        then (builtins.head sortedGroups).groupDisks
        else [ ];

      bestGroup = findBestGroup sizeGroups;

      # Extract disk paths and take the requested count
      selectedDisks = map (d: d.disk) (lib.take count bestGroup);
    in
    if builtins.length selectedDisks >= count
    then selectedDisks
    else throw "Could not find ${toString count} matching disks with criteria: ${builtins.toJSON args}";

  # Detect disk by pattern matching
  detectDiskByPattern =
    { patterns ? [ ]
    , # List of regex patterns to match against /dev/disk/by-id/
      fallback ? null
    ,
    }:
    let
      allDisks = getAllDisks { };

      matchingDisks =
        builtins.filter
          (
            disk:
            lib.any (pattern: builtins.match pattern disk != null) patterns
          )
          allDisks;
    in
    if builtins.length matchingDisks > 0
    then builtins.head matchingDisks
    else if fallback != null
    then fallback
    else throw "No disk matching patterns: ${builtins.toJSON patterns}";

  # Utility function to detect disk by serial number
  detectDiskBySerial = serialNumber:
    let
      allDisks = getAllDisks { };
      matchingDisk =
        lib.findFirst
          (
            disk:
            let
              info = getDiskInfo disk;
              hasError = info ? error;
              validDisk = !hasError && info ? blockdevices && builtins.length info.blockdevices > 0;
              diskData =
                if validDisk
                then builtins.head info.blockdevices
                else { };
            in
            validDisk && diskData ? serial && diskData.serial == serialNumber
          )
          null
          allDisks;
    in
    if matchingDisk != null
    then matchingDisk
    else throw "No disk found with serial number: ${serialNumber}";

  # Generate disk detection at build time for static configurations
  generateDiskConfig =
    { hostName
    , preferredPatterns ? [ ]
    , fallbackDetection ? { }
    ,
    }:
    let
      # Try pattern matching first
      patternResult =
        if builtins.length preferredPatterns > 0
        then try (detectDiskByPattern { patterns = preferredPatterns; }) null
        else null;

      # Fall back to auto-detection
      autoResult =
        if patternResult == null
        then detectPrimaryDisk fallbackDetection
        else patternResult;
    in
    autoResult;
}
