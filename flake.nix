{

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    rust-overlay.url = "github:oxalica/rust-overlay";
  };

  outputs =
    {
      nixpkgs,
      self,
      flake-utils,
      rust-overlay,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        overlays = [ (import rust-overlay) ];
        pkgs = import nixpkgs {
          inherit system overlays;
        };
        lib = pkgs.lib;
      in
      {
        devShells = {
          default = pkgs.mkShell rec {
            nativeBuildInputs = with pkgs; [
              pkg-config
              clang
              # lld is much faster at linking than the default Rust linker
              lld
            ];
            buildInputs =
              with pkgs;
              [
                # rust toolchain
                # use rust-analyzer-nightly for better type inference
                rust-analyzer
                cargo-watch
                cargo-flamegraph
                gnuplot
                (rust-bin.selectLatestNightlyWith (
                  toolchain:
                  toolchain.default.override {
                    extensions = [
                      "rust-src"
                      "rustfmt"
                      "clippy"
                      "llvm-tools"
                    ];
                    targets = [ "x86_64-pc-windows-gnu" ];
                  }
                ))
              ]
              # https://github.com/bevyengine/bevy/blob/v0.14.2/docs/linux_dependencies.md#nix
              ++ (lib.optionals pkgs.stdenv.isLinux [
                udev
                alsa-lib
                vulkan-loader
                xorg.libX11
                xorg.libXcursor
                xorg.libXi
                xorg.libXrandr # To use the x11 feature
                libxkbcommon
                wayland # To use the wayland feature
                # binutils-unwrapped-all-targets
              ])
              ++ (pkgs.lib.optionals pkgs.stdenv.isDarwin [
                # https://discourse.nixos.org/t/the-darwin-sdks-have-been-updated/55295/1
                apple-sdk_15
              ]);

            LD_LIBRARY_PATH = lib.makeLibraryPath buildInputs;
          };
        };
      }
    );
}
