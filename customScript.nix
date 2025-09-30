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
  scripts = [
    {
      name = "gitpush";
      runtimeInputs = [ pkgs.git pkgs.home-manager ];
      text = ''
        read -r -p "Commit message: " msg

        git add .
        git commit -m "$msg"
        git push -u origin master
      '';
    }

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
