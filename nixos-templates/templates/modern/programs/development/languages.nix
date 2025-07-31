{ config
, lib
, pkgs
, ...
}: {
  environment.systemPackages = with pkgs; [
    # Python
    python3
    python3Packages.pip
    python3Packages.virtualenv

    # Node.js
    nodejs
    nodePackages.npm
    nodePackages.yarn

    # Go
    go

    # Rust
    rustup
    cargo

    # Java
    openjdk

    # Perl
    perl

    # Ruby
    ruby

    # Lua
    lua

    # Other languages
    php
    elixir

    # Language servers
    nil # Nix LSP
  ];
}
