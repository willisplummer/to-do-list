{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    utils.url = "github:numtide/flake-utils";
    zig-overlay.url = "github:mitchellh/zig-overlay";
    zls-overlay.url = "github:zigtools/zls";
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      utils,
      zig-overlay,
      zls-overlay,
    }:
    utils.lib.eachDefaultSystem (
      system:
      let
        zig = inputs.zig-overlay.packages.x86_64-linux.master;
        zls = inputs.zls-overlay.packages.x86_64-linux.zls.overrideAttrs (old: {
          nativeBuildInputs = [ zig ];
        });
        pkgs = import nixpkgs {
          inherit system;
          overlays = [
            (final: prev: {
              inherit zig;
            })
          ];
        };
      in
      {
        devShell =
          with pkgs;
          mkShell {
            buildInputs = [
              SDL2
              pkg-config
              xorg.libX11
              xorg.libXcursor
              xorg.libXrandr
              xorg.libXinerama
              xorg.libXi
              xorg.libX11.dev
              wayland
              pulseaudioFull
              unzip
              libxkbcommon
              glfw
              zig
              zls
            ];
          };
      }
    );
}
