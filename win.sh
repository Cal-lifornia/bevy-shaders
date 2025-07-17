#!/usr/bin/env sh
cargo build --target x86_64-pc-windows-gnu &&
cp target/x86_64-pc-windows-gnu/debug/bevy-shaders.exe . &&
exec ./bevy-shaders.exe "$@"
