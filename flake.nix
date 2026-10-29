{
  description = "Nix based development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Locked separately so updating the home config never moves Node off the
    # exact version projects pin (package.json devEngines.runtime, which pnpm
    # enforces).
    nixpkgs-node22.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs =
    {
      nixpkgs,
      home-manager,
      nixpkgs-node22,
      ...
    }:
    let
      forDarwin = nixpkgs.lib.genAttrs [
        "aarch64-darwin"
        "x86_64-darwin"
      ];
    in
    {
      homeConfigurations.nav = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.aarch64-darwin;
        modules = [ ./home.nix ];
      };

      devShells = forDarwin (system: {
        node22 = import ./devshells/node22.nix {
          pkgs = nixpkgs-node22.legacyPackages.${system};
        };
      });
    };
}
