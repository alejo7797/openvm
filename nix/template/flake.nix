{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    systems.url = "github:nix-systems/default";

    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs";

    fenix.url = "github:nix-community/fenix";
    fenix.inputs.nixpkgs.follows = "nixpkgs";

    openvm.url = "github:alejo7797/openvm/nix";
    openvm.inputs.nixpkgs.follows = "nixpkgs";
  };

  nixConfig = {
    extra-substituters = [ "https://openvm.cachix.org" ];
    trusted-public-keys = [ "openvm.cachix.org-1:smgY6he3suDFB1pzLjFeuAk/4N1EKifE13g5UtqdkBY=" ];
  };

  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake
      {
        inherit inputs;
      }
      (
        {
          inputs,
          ...
        }:

        {
          systems = import inputs.systems;

          perSystem =
            {
              inputs',
              pkgs,
              ...
            }:
            let
              rustToolchain = inputs'.fenix.packages.fromToolchainName {
                name = "nightly-2025-08-02";
                sha256 = "sha256-QnkfTssgWvuyHRH3IkYAk3IHpKi4klsOvVIN+hKsqkY=";
              };
            in
            {
              _module.args = {
                pkgs = inputs'.nixpkgs.legacyPackages;
              };

              devShells.default = pkgs.mkShell {

                nativeBuildInputs = [
                  rustToolchain.toolchain
                  inputs'.openvm.packages.openvm
                  inputs'.openvm.packages.solc
                ];

                env = {
                  OPENVM_SKIP_RUSTUP = "1";
                };

                shellHook = ''
                  [[ ! -f Cargo.toml ]] && cargo openvm init
                '';

              };

            };
        }
      );
}
