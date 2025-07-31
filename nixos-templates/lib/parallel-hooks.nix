# Parallel pre-commit hooks implementation
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
    files = "\\.nix$";
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
  
  # Format different file types in parallel
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
}