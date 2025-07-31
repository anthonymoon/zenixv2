# Development tools and pre-commit hooks with parallelization
{ config, lib, pkgs, ... }:

{
  # Development packages for workstations
  environment.systemPackages = with pkgs; lib.mkIf config.networking.networkmanager.enable [
    # Nix development tools
    nixfmt-rfc-style
    statix
    deadnix
    nil # Nix LSP
    nix-tree
    nix-diff
    nix-index
    
    # Parallel processing tools
    parallel
    fd
    ripgrep
    
    # Pre-commit framework
    pre-commit
    
    # Shell script tools
    shellcheck
    shfmt
  ];
  
  # System-wide git configuration for pre-commit
  programs.git = {
    enable = lib.mkDefault true;
    config = {
      init.defaultBranch = "main";
      # Auto-install pre-commit hooks in new repos
      init.templateDir = "~/.git-template";
    };
  };
  
  # Create a system-wide pre-commit template
  environment.etc."skel/.git-template/hooks/pre-commit" = {
    text = ''
      #!/usr/bin/env bash
      # Auto-generated pre-commit hook with parallelization
      
      # Check if pre-commit is available
      if command -v pre-commit >/dev/null 2>&1; then
        # Check if .pre-commit-config.yaml exists
        if [ -f .pre-commit-config.yaml ]; then
          pre-commit run --all-files
        else
          # Run basic parallel checks for Nix files
          echo "Running parallel Nix checks..."
          
          # Find all Nix files
          nix_files=$(find . -name "*.nix" -type f 2>/dev/null | grep -v .git)
          
          if [ -n "$nix_files" ]; then
            # Format check in parallel
            echo "$nix_files" | ${pkgs.parallel}/bin/parallel -j+0 \
              "${pkgs.nixfmt-rfc-style}/bin/nixfmt --check {} || echo 'Format issue: {}'"
            
            # Syntax check in parallel
            echo "$nix_files" | ${pkgs.parallel}/bin/parallel -j+0 \
              "${pkgs.nix}/bin/nix-instantiate --parse {} >/dev/null || echo 'Syntax error: {}'"
          fi
        fi
      fi
    '';
    mode = "0755";
  };
  
  # Convenience script for parallel Nix development
  environment.etc."nixos-templates/parallel-dev.sh" = {
    text = ''
      #!/usr/bin/env bash
      # Parallel development helper functions
      
      # Format all Nix files in parallel
      nix-format-all() {
        echo "Formatting all Nix files in parallel..."
        ${pkgs.fd}/bin/fd -e nix -x echo {} | \
          ${pkgs.parallel}/bin/parallel -j+0 --bar \
            ${pkgs.nixfmt-rfc-style}/bin/nixfmt {}
      }
      
      # Check all Nix files in parallel
      nix-check-all() {
        echo "Checking all Nix files in parallel..."
        ${pkgs.parallel}/bin/parallel -j+0 --halt now,fail=1 ::: \
          "${pkgs.statix}/bin/statix check ." \
          "${pkgs.deadnix}/bin/deadnix ." \
          "${pkgs.nix}/bin/nix flake check --no-build"
      }
      
      # Build all templates in parallel
      nix-build-templates() {
        local templates=("modern" "ephemeral-zfs" "minimal-zfs" "deployment" "personal" "unified" "installer" "legacy")
        echo "Building all templates in parallel..."
        printf '%s\n' "''${templates[@]}" | \
          ${pkgs.parallel}/bin/parallel -j4 --bar \
            "nix build .#nixosConfigurations.example.{}.desktop.config.system.build.toplevel --dry-run"
      }
      
      # Export functions for use
      export -f nix-format-all
      export -f nix-check-all  
      export -f nix-build-templates
      
      echo "Parallel development functions loaded!"
      echo "Available commands:"
      echo "  - nix-format-all     : Format all Nix files in parallel"
      echo "  - nix-check-all      : Run all checks in parallel"
      echo "  - nix-build-templates: Build all templates in parallel (dry-run)"
    '';
    mode = "0755";
  };
}