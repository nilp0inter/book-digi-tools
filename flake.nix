{
  description = "Description for the project";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        # To import a flake module
        # 1. Add foo to inputs
        # 2. Add foo as a parameter to the outputs function
        # 3. Add here: foo.flakeModule

      ];
      systems = [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" "x86_64-darwin" ];
      perSystem = { config, self', inputs', pkgs, system, ... }: {
        # Per-system attributes can be defined here. The self' and inputs'
        # module parameters provide easy access to attributes of the same
        # system.

        # Equivalent to  inputs'.nixpkgs.legacyPackages.hello;
        packages.scanbook = pkgs.callPackage ./scripts/scanbook {};
        packages.default = self'.packages.scanbook;

        devShells.default = pkgs.mkShell {
          packages = [
            self'.packages.scanbook
            pkgs.scantailor-advanced
            pkgs.img2pdf
          ];
          shellHook = ''
            echo
            echo "🚀 Welcome to the book-digi-tools project 🚀"
            echo "============================================"
            echo
            echo "This shell provides tools for scanning and processing books."
            echo "1. You can run 'scanbook' to start the scanning process."
            echo "2. After scanning, you can use 'scantailor' for post-processing."
            echo "3. Use 'img2pdf' to convert images to PDF format."
            echo "4. Enjoy your digitized books!"
            echo
          '';
        };
      };
      flake = {
        # The usual flake attributes can be defined here, including system-
        # agnostic ones like nixosModule and system-enumerating ones, although
        # those are more easily expressed in perSystem.

      };
    };
}
