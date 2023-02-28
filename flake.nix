{
  description = "A presentation about nix";

  outputs = { self, nixpkgs, flake-utils }:
    let lib = import ./lib.nix; in
    {
      inherit lib;
      overlays.default = final: prev: {
        lib = prev.lib // { slides = self.lib; };
      };
    } // flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        slides = pkgs.callPackage lib { };
      in
      slides.mkFlake {
        # inherit pkgs;
        pname = "nix";
        version = "0.0.1";
        src = ./src;
        inputs = [ "nix.slides.md" ];
        theme = pkgs.fetchurl {
          url = "https://raw.githubusercontent.com/math-ac/base16-ksyntaxhighlighting-themes/master/themes/base16-material-darker.theme";
          sha256 = "sha256-rKayBVHpPWPfLKthAUesfNdQDVHtgsZlBA9WV90zVvE=";
        };
      }
    );
}
