#!/usr/bin/env bash
set -euo pipefail
VER="$(cat VERSION.txt)"

# update the .cfg files (adjust the pattern to your real format)
sed -i -E "s/^(version\s*=\s*).*/\1\"${VER}\"/" godot/addons/cyclops_level_builder/plugin.cfg
sed -i -E "s/^(PLUGIN_VERSION\s*:\s*).*/\1${VER}/" .github/workflows/build_addon.yml
#sed -i -E "s/^(version\s*=\s*).*/\1${VER}/" path/to/two.cfg
# any other file carrying the version
#sed -i -E "s/@@VERSION@@/${VER}/g" scripts/any_script.py

#git add -A
#git commit -m "chore: bump to ${VER}" || true
#git tag "v${VER}"
