{
  description = "wwn-ish: iSH-arm64 bundled for Wawona.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    rust-overlay.url = "github:oxalica/rust-overlay";
    rust-overlay.inputs.nixpkgs.follows = "nixpkgs";
    wwn-toolchain.url = "https://flakehub.com/f/Wawona/wwn-toolchain/*";
    wwn-toolchain.inputs.nixpkgs.follows = "nixpkgs";
    wwn-toolchain.inputs.rust-overlay.follows = "rust-overlay";
    
    # non-flake Git repository
    ish-src = {
      url = "github:toastmod/ish-arm64";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, rust-overlay, wwn-toolchain, ish-src, ... }:
    let
      darwinSystems = [ "x86_64-darwin" "aarch64-darwin" ];
      linuxSystems = [ "x86_64-linux" "aarch64-linux" ];
      allSystems = darwinSystems ++ linuxSystems;
      
      # Generates an attribute set mapping all supported systems
      forAll = nixpkgs.lib.genAttrs allSystems;
      
      inherit (wwn-toolchain.lib) withPlatformVariants baseRegistry mkToolchains;

      # Function to instantiate nixpkgs correctly for a given system
      pkgsFor = system: import nixpkgs {
        inherit system;
        overlays = [ (import rust-overlay) ];
        config = {
          allowUnfree = true;
          allowUnsupportedSystem = true;
        };
      };

      ishDir = "./dependencies/libs/ish";

      registryFragment = {
        ish = withPlatformVariants {
          android = ishDir + "/stub.nix";
          wearos = ishDir + "/stub.nix";
          ios = ishDir + "/apple-mobile.nix";
          tvos = ishDir + "/stub.nix";
          ipados = ishDir + "/apple-mobile.nix";
          visionos = ishDir + "/stub.nix";
          watchos = ishDir + "/stub.nix";
          macos = ishDir + "/stub.nix";
          linux = ishDir + "/stub.nix";
        };
      };
    in
    {

      # Resolves the 'packages.<system>.default' attribute lookups
      packages = forAll (system: 
        let
          pkgs = pkgsFor system;
          repoShell = import "${ish-src}/shell.nix" { inherit pkgs; };
        in {
          default = pkgs.stdenv.mkDerivation {
            pname = "ish";
            version = "1.0.0";
            src = ish-src;
            nativeBuildInputs = 
              (repoShell.nativeBuildInputs or []) ++
              (repoShell.buildInputs or []) ++
              (repoShell.packages or []); 

          };
        }
      );

      # Iterates over every architecture to correctly supply the localized 'pkgs' 
      # into the external shell.nix file
      # devShells = forAll (system: {
      #   default = import "${ish}/shell.nix" {
      #     pkgs = pkgsFor system;
      #   };
      # });

      formatter = forAll (system: (pkgsFor system).nixfmt-rfc-style);
    };
}
