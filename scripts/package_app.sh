#!/bin/zsh
set -euo pipefail

script_dir=${0:A:h}
project_dir=${script_dir:h}
configuration=${1:-release}
output_dir=${2:-$project_dir/dist}
app_dir="$output_dir/TypeFlow.app"
staging_dir="$project_dir/.build/TypeFlow.app"

cd "$project_dir"
swift build -c "$configuration"
binary_path=$(swift build -c "$configuration" --show-bin-path)/TypeFlow

if [[ -d "$staging_dir" ]]; then
    rm -rf "$staging_dir"
fi

mkdir -p "$staging_dir/Contents/MacOS" "$staging_dir/Contents/Resources"
cp "$binary_path" "$staging_dir/Contents/MacOS/TypeFlow"
cp "$project_dir/Resources/Info.plist" "$staging_dir/Contents/Info.plist"
codesign --force --deep --sign - "$staging_dir"

mkdir -p "$output_dir"
if [[ -d "$app_dir" ]]; then
    rm -rf "$app_dir"
fi
ditto "$staging_dir" "$app_dir"

echo "$app_dir"
