{ config
, lib
, pkgs
, ...
}: {
  fonts = {
    enableDefaultPackages = true;

    packages = with pkgs; [
      # System fonts
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-emoji
      liberation_ttf

      # Terminal fonts
      terminus_font
      inconsolata

      # Programming fonts
      (nerdfonts.override {
        fonts = [
          "JetBrainsMono"
          "FiraCode"
          "DroidSansMono"
          "Hack"
          "SourceCodePro"
          "RobotoMono"
          "UbuntuMono"
          "DejaVuSansMono"
          "Iosevka"
          "CascadiaCode"
        ];
      })

      # Powerline fonts
      powerline-fonts

      # Icon fonts
      font-awesome
      material-design-icons

      # CJK fonts
      source-han-sans
      source-han-serif
      source-han-mono

      # Other useful fonts
      ubuntu_font_family
      roboto
      roboto-mono
      fira
      fira-code
      fira-mono
      jetbrains-mono
      cascadia-code
      victor-mono
      iosevka

      # System UI fonts
      cantarell-fonts
      dejavu_fonts
      freefont_ttf

      # Math and scientific fonts
      libertinus
      cm_unicode

      # Bitmap fonts (for terminals)
      terminus_font_ttf
      proggyfonts
    ];

    # Font configuration
    fontconfig = {
      enable = true;

      defaultFonts = {
        serif = [ "Liberation Serif" "Noto Serif" ];
        sansSerif = [ "Liberation Sans" "Noto Sans" ];
        monospace = [ "JetBrains Mono" "FiraCode Nerd Font" "Source Code Pro" ];
        emoji = [ "Noto Color Emoji" ];
      };

      # Improve font rendering
      antialias = true;
      hinting = {
        enable = true;
        style = "slight";
      };

      subpixel = {
        rgba = "rgb";
        lcdfilter = "default";
      };
    };
  };
}
