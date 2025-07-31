{ config
, lib
, pkgs
, ...
}: {
  environment.systemPackages = with pkgs; [
    # JSON/YAML processing
    jq
    yq
    jc # Convert output to JSON

    # Text manipulation
    sed
    awk
    perl

    # CSV processing
    csvkit
    miller

    # Markdown
    pandoc
    mdcat

    # Code formatting
    prettier
    black
    rustfmt
    nixfmt

    # Text viewing
    bat
    most

    # Diff tools
    diff-so-fancy
    delta
    colordiff

    # Regular expressions
    pcre

    # Template processing
    envsubst
    gomplate

    # Character encoding
    dos2unix
    convmv

    # Text extraction
    pdfgrep
    xpdf
  ];
}
