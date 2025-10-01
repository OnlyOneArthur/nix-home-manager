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
        runtimeInputs = [];
        text = ''
        cd ~/Projects/ || exit
        nvim '';
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
