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
    yazi
    vlc
    bat
    bat-extras.core
    anki
    hashcat
    hashcat-utils
    anki
    lazygit
    zathura
    john
    johnny
    wine
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
    htop
    qbittorrent
    fastfetch
    fd
    ripgrep
    figlet
    lsd
    pipx
    gamescope
    strawberry

  ];

  # mandoc programs
  programs.man = {
      enable = true;
      package = pkgs.mandoc;
    };
  
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
     ".config/nvim".source = out "${dot}/nvim"; #mkOutOfStoreSymlink
    ".config/kitty".source = out "${dot}/kitty"; #mkOutOfStoreSymlink
     ".config/spotify".source = ./dotfiles/spotify;
     ".config/yazi".source = ./dotfiles/yazi;
     # ".config/waybar".source = ./dotfiles/waybar;
     ".config/Thunar".source = ./dotfiles/Thunar;
     ".config/lazygit".source = ./dotfiles/lazygit;
     ".config/vlc".source =  out "${dot}/vlc"; # mkOutOfStoreSymlink
     # ".config/btop".source = out "${dot}/btop"; # mkOutOfStoreSymlink
     ".config/containers".source = ./dotfiles/containers;
     ".config/weechat".source = ./dotfiles/weechat;
     ".zshrc".source = ./dotfiles/.zshrc;
     ".poshthemes".source = ./dotfiles/.poshthemes;
     ".profile".source = ./dotfiles/.profile;
     ".config/nix".source = ./dotfiles/nix;
     ".gitconfig".source = out "${dot}/.gitconfig"; #mkOutOfStoreSymlink

  };
  # home.file.".gitconfig" = {
  #     source = ./dotfiles/.gitconfig;
  #     force = true;
  #   };

  home.sessionVariables = {
    XDG_DATA_DIRS = "${config.home.profileDirectory}/share:/usr/local/share:/usr/share";
    XDG_ICON_DIRS = "${config.home.profileDirectory}/share/icons:/usr/share:/usr/share/icons";
    EDITOR = "nvim";
    # fixing mandoc path
    MANPATH = "/usr/share/man:/usr/local/share/man:${config.home.profileDirectory}/share/man";
  };

  # export the local/bin path into every shell that recognize
  home.sessionPath = ["$HOME/.local/bin"];

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
