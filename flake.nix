{
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" ];
      perSystem =
        {
          inputs',
          pkgs,
          ...
        }:
        let
          toolchain = inputs'.fenix.packages.fromToolchainFile {
            dir = ./.;
            sha256 = "sha256-SJwZ8g0zF2WrKDVmHrVG3pD2RGoQeo24MEXnNx5FyuI=";
          };
        in
        {
          _module.args = {
            pkgs = inputs'.nixpkgs.legacyPackages;
          };
          devShells.default = pkgs.mkShell {
            nativeBuildInputs = [ toolchain ];
          };
        };
    };
}
