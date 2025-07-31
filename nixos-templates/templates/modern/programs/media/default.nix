{ config
, lib
, pkgs
, ...
}: {
  environment.systemPackages = with pkgs; [
    # Media processing
    ffmpeg-full

    # Image processing
    imagemagick
    graphicsmagick

    # Image viewers (CLI)
    feh
    viu

    # Audio tools
    sox
    flac

    # Video tools
    mediainfo
    mkvtoolnix

    # Image optimization
    optipng
    jpegoptim
    pngquant

    # Screenshot tools
    scrot
    maim

    # OCR
    tesseract

    # Metadata
    exiftool

    # Conversion
    pandoc

    # QR codes
    qrencode
    zbar
  ];
}
