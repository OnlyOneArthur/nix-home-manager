
{ config, pkgs, lib, nixgl, ... }:

let
  # 1) Choose a wrapper. On AMD/Intel iGPU (your A6), this is the right default.
  #    If you ever switch to NVIDIA, swap to nixgl.auto.nixGLNvidia.
  nixGL = nixgl.auto.nixGLDefault;

  # 2) Declare the apps you want to wrap exactly once.
  gpuApps = [
    # name: the command your muscle memory uses
    # bin:  the actual binary inside the package (often same as name)
    # pkg:  the Nix package to call
    { name = "blender"; bin = "blender"; pkg = pkgs.blender; }
    { name = "krita";   bin = "krita";   pkg = pkgs.krita; }
    { name = "mpv";     bin = "mpv";     pkg = pkgs.mpv; }
    { name = "vlc";     bin = "vlc";     pkg = pkgs.vlc; }
    # add more:
    # { name = "godot4"; bin = "godot4"; pkg = pkgs.godot_4; }
    # { name = "obs";    bin = "obs";    pkg = pkgs.obs-studio; }
    # { name = "glxinfo";bin = "glxinfo";pkg = pkgs.glxinfo; }
  ];

  # Helper: script wrapper that always uses nixGL
  mkWrapper = app:
    pkgs.writeShellScriptBin app.name ''
      exec ${nixGL}/bin/nixGL ${app.pkg}/bin/${app.bin} "$@"
    '';

  # Helper: desktop entry that also uses nixGL (so clicking icons works)
  mkDesktop = app: {
    name = "${app.name}-nixgl";
    value = {
      name = "${lib.toUpper app.name} (nixGL)";
      exec = "${nixGL}/bin/nixGL ${app.bin} %U";
      icon = app.name;               # assumes icon name matches; tweak if needed
      terminal = false;
      categories = [ "Graphics" "AudioVideo" "Utility" ];
    };
  };

in
{
  # Expose a small switch if you ever want to disable the wrappers quickly.
  options.gpuApps.enable = lib.mkEnableOption "nixGL wrappers for GPU apps";

  config = lib.mkIf config.gpuApps.enable {
    # Ensure nixGL and the underlying apps are present
    home.packages =
      [ nixGL ] ++ (map (a: a.pkg) gpuApps) ++ (map mkWrapper gpuApps);

    # Desktop entries show up as “APPNAME (nixGL)”
    xdg.desktopEntries =
      lib.listToAttrs (map mkDesktop gpuApps);

    # Make sure ~/.local/bin is early in PATH (wrappers first)
    programs.zsh.initExtra = lib.mkAfter ''
      path=("$HOME/.local/bin" $path)
    '';
  };
}
