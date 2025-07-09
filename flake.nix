{
  description = "A flake for book digitization tools";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    pyproject-nix = {
      url = "github:pyproject-nix/pyproject.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    uv2nix = {
      url = "github:pyproject-nix/uv2nix";
      inputs.pyproject-nix.follows = "pyproject-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    pyproject-build-systems = {
      url = "github:pyproject-nix/build-system-pkgs";
      inputs.pyproject-nix.follows = "pyproject-nix";
      inputs.uv2nix.follows = "uv2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
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

        packages.mistralocr = import ./scripts/mistralocr ( inputs // { inherit pkgs; });
        packages.ai-add-bookmarks = pkgs.callPackage ./scripts/ai-add-bookmarks {};
        packages.scanbook = pkgs.callPackage ./scripts/scanbook {};
        packages.default = self'.packages.scanbook;

        devShells.default = pkgs.mkShell {
          packages = [
            self'.packages.scanbook
            self'.packages.ai-add-bookmarks
            self'.packages.mistralocr

            pkgs.scantailor-advanced
            pkgs.img2pdf
            pkgs.ocrmypdf
            pkgs.tesseract5
            pkgs.pdfcpu
            pkgs.poppler-utils
          ];
          shellHook = ''
            echo
            echo "🚀 Welcome to the book-digi-tools project 🚀"
            echo "============================================"
            echo
            echo "This shell provides tools for scanning and processing books."
            echo
            echo "  1. You can run 'scanbook' to start the scanning process."
            echo "  2. After scanning, you can use 'scantailor' for post-processing."
            echo "  3. Use 'img2pdf' to convert images to PDF format."
            echo "  4. Use 'ocrmypdf' to add OCR text to your PDFs."
            echo "  5. Use 'pdfcpu' for PDF manipulation tasks."
            echo "  6. Use 'ai-add-bookmarks' to add AI-generated bookmarks to your PDFs."
            echo "  7. Use 'mistralocr' for converting pdf's to markdown with formula support and image extraction."
            echo "  n. Enjoy your digitized books!"
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
