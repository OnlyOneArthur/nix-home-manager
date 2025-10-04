{
  description = "Home Manager configuration of arthur";

  inputs = {
    # Specify the source of Home Manager and Nixpkgs.
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
     # nixgl
      nixgl.url = "github:guibou/nixGL";
    };
  };

  outputs =
    { nixpkgs, home-manager, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      # nix gl
      nixGLp = nixgl.packages.${system};

    in
    {
      homeConfigurations."arthur" = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        extraSpecialArgs = {nixGL = nixGLp; };

        # Specify your home configuration modules here, for example,
        # the path to your home.nix.
        modules = [ 
        ./home.nix 
        ./customScript.nix


        ];

        # Optionally use extraSpecialArgs
        # to pass through arguments to home.nix
      };
    };
}
