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
          inherit (pkgs)
            autoPatchelfHook
            stdenv
            fetchurl
            ;

          rustToolchain = inputs'.fenix.packages.fromToolchainFile {
            dir = ./.;
            sha256 = "sha256-SJwZ8g0zF2WrKDVmHrVG3pD2RGoQeo24MEXnNx5FyuI=";
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

          devShells.default = pkgs.mkShell {
            nativeBuildInputs = [
              solc_0_8_19
              rustToolchain
            ];
          };
        };
    };
}
