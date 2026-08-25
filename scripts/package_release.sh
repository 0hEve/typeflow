#!/bin/zsh
set -euo pipefail

script_dir=${0:A:h}
project_dir=${script_dir:h}
plist="$project_dir/Resources/Info.plist"
version=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$plist")
architecture=$(uname -m)
output_dir=${1:-$project_dir/dist}
archive="$output_dir/TypeFlow-$version-macos-$architecture.zip"

"$script_dir/package_app.sh" release "$output_dir"

if [[ -e "$archive" ]]; then
    rm "$archive"
fi

ditto -c -k --sequesterRsrc --keepParent "$output_dir/TypeFlow.app" "$archive"
shasum -a 256 "$archive"
