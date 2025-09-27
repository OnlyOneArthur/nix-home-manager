{ config, pkgs, ... }:

{
  home.username = "arthur";
  home.homeDirectory = "/home/arthur";

  # release notes.
  home.stateVersion = "25.05"; # Please read the comment before changing.

  # manage the installed packages
  home.packages = with pkgs; [
    spotify
    discord
    yazi
    vlc
    bat
    bat-extras.core
    blender
    anki
    hashcat
    hashcat-utils
    anki
    lazygit
    zathura
    john
    johnny
    wine
    bottles
    lolcat
    thunderbird
    syncthing
    tealdeer
    cowsay
    cbonsai
    cmatrix
    stegseek
    wget
    weechat
    spice-vdagent


  ];
  
  # manage the allow unfree license packages
  nixpkgs.config.allowUnfreePredicate = 
  pkg: builtins.elem (pkgs.lib.getName pkg) [

  "spotify"
  "discord"
  "brave"
  "zoom-us"
  ];

  # manage symlink file or directory
  home.file = {
     ".config/nvim".source = ./dotfiles/nvim;
     ".config/kitty".source = ./dotfiles/kitty;
     ".config/spotify".source = ./dotfiles/spotify;
     ".config/yazi".source = ./dotfiles/yazi;
     ".config/waybar".source = ./dotfiles/waybar;
     ".config/Thunar".source = ./dotfiles/Thunar;
     ".config/lazygit".source = ./dotfiles/lazygit;
     ".config/vlc".source = ./dotfiles/vlc;
     ".config/btop".source = ./dotfiles/btop;
  };

  home.sessionVariables = {
    XDG_DATA_DIRS = "${config.home.profileDirectory}/share:/usr/local/share:/usr/share";
    XDG_ICON_DIRS = "${config.home.profileDirectory}/share/icons:/usr/share:/usr/share/icons";
    # EDITOR = "emacs";
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
