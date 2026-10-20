#!/bin/zsh
set -eu
cd -- "${0:A:h}"
orbit_output="${1:-$PWD/build/Neon Orbit.app}"
orbit_stage="$(mktemp -d "${TMPDIR:-/tmp}/neon-orbit-build.XXXXXX")"
trap 'rm -rf "$orbit_stage"' EXIT
orbit_app="$orbit_stage/Neon Orbit.app"
orbit_cache="${TMPDIR:-/tmp}/neon-orbit-swift-cache"
orbit_arch="$(uname -m)"
mkdir -p "$orbit_app/Contents/MacOS" "$orbit_app/Contents/Resources" "$orbit_cache"
xcrun swift -module-cache-path "$orbit_cache" scripts/GenerateIcon.swift "$orbit_app/Contents/Resources/AppIcon.icns"
xcrun swiftc src/Launcher.swift -o "$orbit_app/Contents/MacOS/NeonOrbit" -framework Cocoa -framework WebKit -module-cache-path "$orbit_cache" -target "$orbit_arch-apple-macosx13.0"
cp src/Info.plist "$orbit_app/Contents/Info.plist"
cp src/animation.html LICENSE NOTICE.md "$orbit_app/Contents/Resources/"
codesign --force --sign - "$orbit_app"
codesign --verify --deep --strict "$orbit_app"
mkdir -p "${orbit_output:h}"
ditto --norsrc --noextattr "$orbit_app" "$orbit_output"
echo "Built: $orbit_output"
