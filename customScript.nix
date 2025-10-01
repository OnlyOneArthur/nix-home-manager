{config, pkgs, ...}:

let
  # Helper: create a wrapped script that brings its own tools
  mkScript = { name, runtimeInputs ? [ ], text }:
    pkgs.writeShellApplication {
      inherit name runtimeInputs;
      text = ''
        #!/usr/bin/env bash
        set -euo pipefail
        ${text}
      '';
    };

  # Define your scripts here
  # script to automate git workflow
  scripts = [
    {
      name = "gitpush";
      runtimeInputs = [ pkgs.git];
      text = ''
        branch=$(git rev-parse --abbrev-ref HEAD)
        git add .
        read -r -p "Commit message: " msg

        git commit -m "$msg"
        git push -u origin "$branch"
      '';
    }
   # another script here
    {
        name = "pro";
        runtimeInputs = [pkgs.neovim];
        text = ''
        cd "$HOME/Projects" || exit
        nvim '';
    }
   # script for nix automation push
    {

      name = "nixpush";
      runtimeInputs = [pkgs.git];
      text = ''
      cd "$HOME/nix-home-manager" || exit

      git add .

      read -r -p "Enter commit message: " msg

      git commit -m "$msg"

      git push -u origin master

      home-manager switch --flake .#arthur
      '';

    }
     # script to auto open obsidian nvim in my obsidian vault dir
    {
      name = "obsidian";
      runtimeInputs = [];
      text = ''
      cd "$HOME/Documents/Obsidian_vault/" || exit
      nvim
      '';

    }


  ];

  pkgsFromScripts = map (s: mkScript s) scripts;

in
{
  home.packages = pkgsFromScripts;

  # # Optional: shell shortcuts
  # programs.zsh.shellAliases = {
  #   np = "nixpush";
  #   ip = "myip";
  # };
}
