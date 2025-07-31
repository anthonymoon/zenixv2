{ config
, lib
, pkgs
, ...
}: {
  environment.systemPackages = with pkgs; [
    # Version control
    git
    git-lfs

    # Build tools
    gnumake
    cmake
    ninja
    pkg-config
    autoconf
    automake
    libtool

    # Compilers
    gcc
    clang
    llvm

    # Debugging
    gdb
    valgrind
    strace
    ltrace

    # Binary tools
    binutils
    patchelf

    # Documentation
    doxygen

    # Package management
    nix-index
    nix-tree
    nix-diff
  ];
}
