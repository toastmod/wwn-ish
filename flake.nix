{
  description = "wwn-ish: iSH-arm64 bundled for Wawona.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils"; 
    rust-overlay.url = "github:oxalica/rust-overlay";
    rust-overlay.inputs.nixpkgs.follows = "nixpkgs";
    wwn-toolchain.url = "https://flakehub.com/f/Wawona/wwn-toolchain/*";
    wwn-toolchain.inputs.nixpkgs.follows = "nixpkgs";
    wwn-toolchain.inputs.rust-overlay.follows = "rust-overlay";
  };

  # Added flake-utils to the arguments list
  outputs = { self, nixpkgs, flake-utils, rust-overlay, wwn-toolchain, ... }:
    let
      # Moved ishDir inside a let block
      ishDir = ./dependencies/libs/ish-arm64;
    in
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        
        childShell = import "${ishDir}/shell.nix" { inherit pkgs; };
      in
      {
        packages.default = pkgs.stdenv.mkDerivation {
          pname = "ish-arm64";
          version = "1.0.0";
          src = ishDir;

          nativeBuildInputs = childShell.nativeBuildInputs or [ ]; 
        };
      }
    );
}
