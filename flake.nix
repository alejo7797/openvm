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
    inputs.flake-parts.lib.mkFlake { inherit inputs; } (
      { lib, ... }:
      {
        systems = [ "x86_64-linux" ];
        perSystem =
          {
            inputs',
            pkgs,
            self',
            ...
          }:
          let
            inherit (pkgs)
              autoPatchelfHook
              fetchurl
              makeRustPlatform
              stdenv
              ;

            buildToolchain = inputs'.fenix.packages.fromToolchainFile {
              dir = ./.;
              sha256 = "sha256-SJwZ8g0zF2WrKDVmHrVG3pD2RGoQeo24MEXnNx5FyuI=";
            };

            buildRustPlatform = makeRustPlatform {
              cargo = buildToolchain;
              rustc = buildToolchain;
            };

            openvmToolchain = inputs'.fenix.packages.fromToolchainName {
              name = "nightly-2025-08-02";
              sha256 = "sha256-QnkfTssgWvuyHRH3IkYAk3IHpKi4klsOvVIN+hKsqkY=";
            };

            solc_0_8_19 = stdenv.mkDerivation {
              pname = "solc";
              version = "0.8.19";
              src = fetchurl {
                url = "https://binaries.soliditylang.org/linux-amd64/solc-linux-amd64-v0.8.19+commit.7dd6d404";
                hash = "sha256-elwdPcmo66Yrsuw3GSyReK5f6KVKVuVXP9PJwXzZ60g=";
              };
              dontUnpack = true;
              nativeBuildInputs = [
                autoPatchelfHook
              ];
              installPhase = ''
                runHook preInstall
                install -Dm755 $src $out/bin/solc
                runHook postInstall
              '';
            };
          in
          {
            _module.args = {
              pkgs = inputs'.nixpkgs.legacyPackages;
            };

            devShells = {

              dev = pkgs.mkShell {
                nativeBuildInputs = [
                  buildToolchain
                ];
              };

              openvm = pkgs.mkShell {
                nativeBuildInputs = [
                  openvmToolchain.toolchain
                  solc_0_8_19
                  self'.packages.openvm
                ];
                env = {
                  OPENVM_SKIP_RUSTUP = "1";
                };
              };

              default = self'.devShells.dev;

            };

            packages = {

              openvm = buildRustPlatform.buildRustPackage {
                pname = "openvm";
                version = "2.0.0-beta.1";
                src = ./.;
                cargoLock = {
                  lockFile = ./Cargo.lock;
                  allowBuiltinFetchGit = true;
                };
                cargoBuildFlags = [
                  "--package"
                  "cargo-openvm"
                ];
                doCheck = false;
                meta = {
                  description = "Performant and modular zkVM framework built for customization and extensibility";
                  homepage = "https://openvm.dev/";
                  license = with lib.licenses; [
                    asl20
                    mit
                  ];
                  mainProgram = "cargo-openvm";
                };
              };

              default = self'.packages.openvm;

            };
          };
      }
    );
}
