{ lib, stdenvNoCC, fetchFromGitHub, pandoc, xdg-utils }:

let
  revealSrc = fetchFromGitHub { owner = "hakimel"; repo = "reveal.js"; rev = "4.4.0"; sha256 = "sha256-bqNgaBT6WPfumhdG1VPZ6ngn0QA9RDuVtVJtVwxbOd4="; };
  mkCmd = { src, inputs ? [ "*.md" ], standalone ? true, incremental ? true, theme ? null, ... }@attrs:
    "${pandoc}/bin/pandoc --verbose ${toString inputs} --to=revealjs -M revealjs-url=${revealSrc}"
    + lib.optionalString standalone " --standalone"
    + lib.optionalString incremental " --incremental"
    + lib.optionalString (theme != null) " --highlight-style '${theme}'";
  mkDerivation = { pname, ... }@attrs: stdenvNoCC.mkDerivation {
    inherit (attrs) pname version src;
    buildPhase = mkCmd attrs + " > out.html";
    installPhase = ''
      mkdir -vp $out/share
      cp -v out.html $out/share/${pname}.html
    '';
  };
  mkFull = { pname, version, ... }@attrs: stdenvNoCC.mkDerivation {
    inherit (attrs) pname;
    version = version + "-full";
    dontUnpack = true;
    installPhase = ''
      mkdir -vp $out/share
      ln -vs ${mkDerivation attrs}/share/${pname}.html $out/share
      tee $out/open <<EOF
      #!${stdenvNoCC.shell}
      ${xdg-utils}/bin/xdg-open $out/share/${pname}.html >/dev/null 2>&1 & disown
      EOF
      chmod +x $out/open
    '';
  };
  mkFlake = attrs: rec {
    packages = { slides = mkDerivation attrs; full = mkFull attrs; default = packages.full; };
    apps.default = { type = "app"; program = "${packages.full}/open"; };
  };
in
{ inherit mkCmd mkDerivation mkFull mkFlake; }
