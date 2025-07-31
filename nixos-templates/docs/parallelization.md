# Parallelization Strategies for Pre-commit Hooks

## 🚀 Native Pre-commit Parallelization

```nix
# flake.nix - Basic parallel configuration
{
  checks.${system}.pre-commit-check = pre-commit-hooks.lib.${system}.run {
    src = ./.;
    
    # Enable parallel execution
    settings = {
      # Run hooks in parallel (not sequential)
      parallel = true;
      
      # Number of concurrent hooks
      # Defaults to number of CPU cores
      jobs = 8;  # or use null for auto-detect
      
      # Fail fast - stop on first error
      fail_fast = false;  # Keep false for parallel benefits
    };
    
    hooks = {
      # Parallel-safe hooks
      nixfmt-rfc-style.enable = true;
      statix.enable = true;
      deadnix.enable = true;
      trailing-whitespace.enable = true;
      end-of-file-fixer.enable = true;
    };
  };
}
```

## 🔧 Advanced Parallel Hook Implementation

```nix
# lib/parallel-hooks.nix
{ pkgs, lib, ... }:
let
  # Parallel execution wrapper
  parallelWrapper = { name, commands, maxJobs ? null }: 
    pkgs.writeShellScript "parallel-${name}" ''
      set -euo pipefail
      
      # Determine max jobs
      MAX_JOBS=''${maxJobs:-$(${pkgs.coreutils}/bin/nproc)}
      
      # Create temp directory for job management
      WORK_DIR=$(${pkgs.coreutils}/bin/mktemp -d)
      trap "${pkgs.coreutils}/bin/rm -rf $WORK_DIR" EXIT
      
      # Job counter
      job_count=0
      
      # Execute job with slot management
      run_job() {
        local slot=$1
        local cmd=$2
        shift 2
        
        echo "[Slot $slot] Starting: $cmd" >&2
        if $cmd "$@" > "$WORK_DIR/out.$slot" 2>&1; then
          echo "[Slot $slot] Success: $cmd" >&2
        else
          echo "[Slot $slot] Failed: $cmd" >&2
          echo "=== Output ===" >&2
          cat "$WORK_DIR/out.$slot" >&2
          echo "==============" >&2
          return 1
        fi
      }
      
      # Process queue
      process_queue() {
        local -a pids=()
        local slot=0
        
        ${lib.concatStringsSep "\n" (lib.imap0 (i: cmd: ''
          # Wait for available slot
          while [ ''${#pids[@]} -ge $MAX_JOBS ]; do
            for idx in "''${!pids[@]}"; do
              if ! kill -0 "''${pids[$idx]}" 2>/dev/null; then
                wait "''${pids[$idx]}"
                local exit_code=$?
                unset pids[$idx]
                pids=("''${pids[@]}")  # Reindex array
                [ $exit_code -ne 0 ] && return $exit_code
                break
              fi
            done
            sleep 0.1
          done
          
          # Launch job
          run_job $((slot % MAX_JOBS)) "${cmd}" "$@" &
          pids+=($!)
          ((slot++))
        '') commands)}
        
        # Wait for remaining jobs
        for pid in "''${pids[@]}"; do
          wait "$pid" || return $?
        done
      }
      
      # Execute
      process_queue "$@"
    '';
in
{
  # Parallel Nix file checker
  parallel-nix-check = {
    enable = true;
    entry = parallelWrapper {
      name = "nix-check";
      commands = [
        "${pkgs.statix}/bin/statix check"
        "${pkgs.deadnix}/bin/deadnix --fail"
        "${pkgs.nix}/bin/nix flake check --no-build"
        "${pkgs.nil}/bin/nil diagnostics"
      ];
    };
    pass_filenames = false;
    stages = [ "commit" ];
  };
  
  # Parallel file processor
  parallel-file-processor = {
    enable = true;
    entry = pkgs.writeShellScript "parallel-files" ''
      # Use GNU parallel for file processing
      echo "$@" | ${pkgs.parallel}/bin/parallel -j+0 --halt now,fail=1 \
        ${pkgs.nixfmt-rfc-style}/bin/nixfmt {}
    '';
    files = ''\\.nix';
    stages = [ "commit" ];
  };
  
  # Parallel test runner
  parallel-test-runner = {
    enable = true;
    entry = pkgs.writeShellScript "parallel-tests" ''
      # Find all test files
      ${pkgs.fd}/bin/fd -e nix . tests/ -x echo {} | \
        ${pkgs.parallel}/bin/parallel -j+0 --halt now,fail=1 \
          "${pkgs.nix}/bin/nix eval -f {} --arg pkgs 'import <nixpkgs> {}'"
    '';
    pass_filenames = false;
    stages = [ "push" ];
  };
}
```

## 🎯 Batched Operations

```nix
# lib/batched-hooks.nix
{ pkgs, lib, ... }:
{
  # Batch file operations
  batch-formatter = {
    enable = true;
    entry = pkgs.writeShellScript "batch-format" ''
      # Collect all Nix files
      files=()
      for f in "$@"; do
        [[ "$f" == *.nix ]] && files+=("$f")
      done
      
      # Process in batches
      batch_size=50
      for ((i=0; i<''${#files[@]}; i+=batch_size)); do
        batch=("''${files[@]:i:batch_size}")
        echo "Processing batch of ''${#batch[@]} files..."
        
        # Run formatter in parallel on batch
        printf '%s\n' "''${batch[@]}" | \
          ${pkgs.parallel}/bin/parallel -j+0 \
            ${pkgs.nixfmt-rfc-style}/bin/nixfmt --check {}
      done
    '';
    stages = [ "commit" ];
  };
  
  # Parallel syntax checker with batching
  batch-syntax-check = {
    enable = true;
    entry = pkgs.writeShellScript "batch-syntax" ''
      # Create work queue
      QUEUE=$(${pkgs.coreutils}/bin/mktemp)
      trap "${pkgs.coreutils}/bin/rm -f $QUEUE" EXIT
      
      # Add files to queue
      for f in "$@"; do
        [[ "$f" == *.nix ]] && echo "$f" >> "$QUEUE"
      done
      
      # Process queue in parallel
      ${pkgs.parallel}/bin/parallel -a "$QUEUE" -j+0 --bar \
        "${pkgs.nix}/bin/nix-instantiate --parse {} > /dev/null"
    '';
    stages = [ "commit" ];
  };
}
```

## 🔄 Async Hook Runner

```nix
# lib/async-hooks.nix
{ pkgs, lib, ... }:
let
  asyncRunner = pkgs.writeShellApplication {
    name = "async-hook-runner";
    runtimeInputs = with pkgs; [ 
      coreutils 
      gnugrep 
      gawk 
      ps 
      util-linux 
    ];
    text = ''
      # Hook definitions
      declare -A hooks=(
        ["format"]="${pkgs.nixfmt-rfc-style}/bin/nixfmt"
        ["statix"]="${pkgs.statix}/bin/statix check"
        ["deadnix"]="${pkgs.deadnix}/bin/deadnix"
        ["eval"]="${pkgs.nix}/bin/nix flake check --no-build"
      )
      
      # Status tracking
      declare -A status=()
      declare -A pids=()
      
      # Launch hooks asynchronously
      for name in "''${!hooks[@]}"; do
        echo "Starting $name..."
        "''${hooks[$name]}" "$@" &
        pids[$name]=$!
      done
      
      # Monitor progress
      while [ ''${#pids[@]} -gt 0 ]; do
        for name in "''${!pids[@]}"; do
          if ! kill -0 "''${pids[$name]}" 2>/dev/null; then
            wait "''${pids[$name]}"
            status[$name]=$?
            unset pids[$name]
            
            if [ "''${status[$name]}" -eq 0 ]; then
              echo "✓ $name completed successfully"
            else
              echo "✗ $name failed with exit code ''${status[$name]}"
            fi
          fi
        done
        sleep 0.1
      done
      
      # Check overall status
      for name in "''${!status[@]}"; do
        [ "''${status[$name]}" -ne 0 ] && exit 1
      done
    '';
  };
in
{
  async-all-checks = {
    enable = true;
    entry = "${asyncRunner}/bin/async-hook-runner";
    pass_filenames = false;
    stages = [ "push" ];
  };
}
```

## 🌊 Stream Processing

```nix
# lib/stream-hooks.nix
{ pkgs, lib, ... }:
{
  # Stream-based file processor
  stream-processor = {
    enable = true;
    entry = pkgs.writeShellScript "stream-process" ''
      # Use xargs for parallel stream processing
      printf '%s\n' "$@" | \
        ${pkgs.findutils}/bin/xargs -P "$(${pkgs.coreutils}/bin/nproc)" -I {} \
          sh -c '
            if ${pkgs.nixfmt-rfc-style}/bin/nixfmt --check {} 2>/dev/null; then
              echo "✓ {}"
            else
              ${pkgs.nixfmt-rfc-style}/bin/nixfmt {} && echo "✓ {} (formatted)"
            fi
          '
    '';
    stages = [ "commit" ];
  };
  
  # Parallel evaluation pipeline
  eval-pipeline = {
    enable = true;
    entry = pkgs.writeShellScript "eval-pipeline" ''
      export NIX_BUILD_CORES=$(${pkgs.coreutils}/bin/nproc)
      
      # Build derivation pipeline
      find . -name "*.nix" -type f | \
        ${pkgs.parallel}/bin/parallel --pipe -N100 --round-robin -j+0 \
          "${pkgs.fd}/bin/fd -e nix . {} -x ${pkgs.nix}/bin/nix-instantiate --parse {} \;"
    '';
    pass_filenames = false;
    stages = [ "push" ];
  };
}
```

## 🎪 Advanced Parallelization Techniques

```nix
# flake.nix - Complete parallel setup
{
  checks.${system}.pre-commit-check = pre-commit-hooks.lib.${system}.run {
    src = ./.;
    
    settings = {
      parallel = true;
      jobs = null;  # Auto-detect
      fail_fast = false;
    };
    
    hooks = {
      # Group 1: Format checks (highly parallel)
      format-parallel = {
        enable = true;
        entry = pkgs.writeShellScript "format-all" ''
          export PARALLEL_JOBS="-j+0"
          
          # Format different file types in parallel
          {
            ${pkgs.fd}/bin/fd -e nix . -x echo {} | \
              ${pkgs.parallel}/bin/parallel $PARALLEL_JOBS \
                ${pkgs.nixfmt-rfc-style}/bin/nixfmt --check {} &
            
            ${pkgs.fd}/bin/fd -e sh . -x echo {} | \
              ${pkgs.parallel}/bin/parallel $PARALLEL_JOBS \
                ${pkgs.shfmt}/bin/shfmt -d {} &
            
            ${pkgs.fd}/bin/fd -e md . -x echo {} | \
              ${pkgs.parallel}/bin/parallel $PARALLEL_JOBS \
                ${pkgs.markdownlint-cli}/bin/markdownlint {} &
          } | wait
        '';
        pass_filenames = false;
        stages = [ "commit" ];
      };
      
      # Group 2: Analysis (CPU-bound, benefit from parallelization)
      analysis-parallel = {
        enable = true;
        entry = pkgs.writeShellScript "analyze-all" ''
          # Run multiple analyzers concurrently
          ${pkgs.parallel}/bin/parallel -j+0 --halt now,fail=1 ::: \
            "${pkgs.statix}/bin/statix check ." \
            "${pkgs.deadnix}/bin/deadnix --fail ." \
            "${pkgs.vulnix}/bin/vulnix -S ." \
            "${pkgs.nix-linter}/bin/nix-linter -r ."
        '';
        pass_filenames = false;
        stages = [ "push" ];
      };
      
      # Group 3: Build matrix (system-specific)
      build-matrix = {
        enable = true;
        entry = pkgs.writeShellScript "build-matrix" ''
          systems=("x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin")
          configs=("desktop" "server" "minimal")
          
          # Build all combinations in parallel
          printf '%s\n' "''${systems[@]}" | \
            ${pkgs.parallel}/bin/parallel -j4 --tag --bar \
              "printf '%s\n' ''${configs[@]} | \
                ${pkgs.parallel}/bin/parallel -j2 \
                  '${pkgs.nix}/bin/nix build .#nixosConfigurations.{2}-{1}.config.system.build.toplevel \
                    --system {1} --dry-run' :::: - ::: {}"
        '';
        pass_filenames = false;
        stages = [ "push" ];
      };
    };
  };
}
```

## 📊 Performance Tips

### CPU vs I/O Bound Tasks:
```nix
# CPU-bound: limit to CPU cores
jobs = config.nix.maxJobs or "$(nproc)";

# I/O-bound: can exceed CPU cores
jobs = "$(( $(nproc) * 2 ))";
```

### Memory-Aware Parallelization:
```nix
entry = pkgs.writeShellScript "memory-aware" ''
  # Adjust parallelism based on available memory
  mem_gb=$(free -g | awk '/^Mem:/{print $7}')
  jobs=$(( mem_gb / 2 )) # 2GB per job
  jobs=$(( jobs < 1 ? 1 : jobs ))
  
  parallel -j$jobs ...
'';
```

### Incremental Processing:
```nix
# Only process changed files
entry = ''
  git diff --cached --name-only --diff-filter=ACM | \
    grep '\.nix | \
    parallel -j+0 nixfmt --check {}
'';
```

### Load Balancing:
```nix
# Use GNU parallel's load balancing
parallel --load 80% --noswap --memfree 1G ...
```