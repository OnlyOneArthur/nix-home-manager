{ config, pkgs, ... }:


let
  home = config.home.homeDirectory;
  repo = "${home}/nix-home-manager";
  dot  = "${repo}/dotfiles";
  out  = p: config.lib.file.mkOutOfStoreSymlink p;
in
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
    btop
    processing


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

  # directory symlink
     ".config/nvim".source = ./dotfiles/nvim;
     ".config/kitty".source = ./dotfiles/kitty;
     ".config/spotify".source = ./dotfiles/spotify;
     ".config/yazi".source = ./dotfiles/yazi;
     ".config/waybar".source = ./dotfiles/waybar;
     ".config/Thunar".source = ./dotfiles/Thunar;
     ".config/lazygit".source = ./dotfiles/lazygit;
     ".config/vlc".source = ./dotfiles/vlc;
     ".config/btop".source = out "${dot}/btop"; # mkOutOfStoreSymlink
     ".config/containers".source = ./dotfiles/containers;
     ".config/blender".source = ./dotfiles/blender;
     ".config/weechat".source = ./dotfiles/weechat;
     ".zshrc".source = ./dotfiles/.zshrc;
     ".poshthemes".source = ./dotfiles/.poshthemes;
     ".profile".source = ./dotfiles/.profile;
     ".config/nix".source = ./dotfiles/nix;

    # bash script
  };

  home.sessionVariables = {
    XDG_DATA_DIRS = "${config.home.profileDirectory}/share:/usr/local/share:/usr/share";
    XDG_ICON_DIRS = "${config.home.profileDirectory}/share/icons:/usr/share:/usr/share/icons";
    # EDITOR = "emacs";
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
