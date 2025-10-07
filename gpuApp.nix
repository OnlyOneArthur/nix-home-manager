{ config, pkgs, lib, nixgl, ... }:

let
  # AMD/Intel default; if you switch to NVIDIA later, use nixgl.auto.nixGLNvidia
  nixGL = nixgl.auto.nixGLDefault;

  # List GPU apps ONCE here.
  gpuApps = [
    { name = "blender"; bin = "blender"; pkg = pkgs.blender; }
    # add more when you want:
    # { name = "krita";   bin = "krita";   pkg = pkgs.krita; }
    # { name = "mpv";     bin = "mpv";     pkg = pkgs.mpv; }
    # { name = "vlc";     bin = "vlc";     pkg = pkgs.vlc; }
    # { name = "godot4";  bin = "godot4";  pkg = pkgs.godot_4; }
    # { name = "obs";     bin = "obs";     pkg = pkgs.obs-studio; }
  ];

  # CLI wrapper: ensures we always call nixGL with the real store binary
  mkWrapper = app:
    pkgs.writeShellScriptBin app.name ''
      exec ${nixGL}/bin/nixGL ${app.pkg}/bin/${app.bin} "$@"
    '';

  # Desktop entry: launcher menu also uses nixGL explicitly
  mkDesktop = app: {
    name = "${app.name}-nixgl";
    value = {
      name = "${lib.toUpper app.name} (nixGL)";
      exec = "${nixGL}/bin/nixGL ${app.pkg}/bin/${app.bin} %U";
      icon = app.name;      # adjust if icon name differs
      terminal = false;
      categories = [ "Graphics" "AudioVideo" "Utility" ];
    };
  };
in
{
  options.gpuApps.enable = lib.mkEnableOption "nixGL wrappers for GPU apps";

  config = lib.mkIf config.gpuApps.enable {
    # IMPORTANT: include ONLY the wrappers (and nixGL itself).
    # Do NOT also list the raw pkgs here, to avoid name collisions.
    home.packages = [ nixGL ] ++ (map mkWrapper gpuApps);

    # App-launcher entries labelled "(nixGL)"
    xdg.desktopEntries = lib.listToAttrs (map mkDesktop gpuApps);

    # Ensure ~/.local/bin (writeShellScriptBin) is early in PATH
    home.sessionPath = lib.mkBefore [ "$HOME/.local/bin" ];
  };
}
