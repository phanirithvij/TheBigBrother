{
  description = "";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      nixpkgs,
      flake-utils,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        python = pkgs.python3.withPackages (
          pp: with pp; [
            wheel
            opencv-python
            (pkgs.callPackage ./nix/mediapipe.nix { })
            tkinter
            pynput
            playsound
            docopt
          ]
        );

        nativeBuildInputs = with pkgs; [
          python
        ];
      in
      {
        devShells.default = pkgs.mkShell { inherit nativeBuildInputs; };

        packages.default = pkgs.stdenv.mkDerivation {
          pname = "bigbrother";
          version = "0.0.1";
          src = ./.;
          patches = [
            (pkgs.replaceVars ./nix/mp3.patch { policemp3 = "${placeholder "out"}/share/police.mp3"; })
          ];

          installPhase = ''
                        chmod +x bigbrother
            	    patchShebangs bigbrother
                        mkdir -p $out/bin $out/share
                        cp bigbrother $out/bin
                        cp police.mp3 $out/share
          '';
          # True if tests
          doCheck = false;

          inherit nativeBuildInputs;
        };
      }
    );
}
