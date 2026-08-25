#!/bin/zsh
set -euo pipefail

script_dir=${0:A:h}
project_dir=${script_dir:h}
check_dir="$project_dir/.build/policy-check"

mkdir -p "$check_dir"

swiftc \
    -parse-as-library \
    -enable-testing \
    -emit-module \
    -emit-library \
    -module-name TypeFlowPolicy \
    "$project_dir/Sources/TypeFlow/TypingPolicy.swift" \
    "$project_dir/Sources/TypeFlow/TypingPreferences.swift" \
    -emit-module-path "$check_dir/TypeFlowPolicy.swiftmodule" \
    -o "$check_dir/libTypeFlowPolicy.dylib"

swiftc \
    -I "$check_dir" \
    -L "$check_dir" \
    -lTypeFlowPolicy \
    "$project_dir/scripts/PolicyCheck.swift" \
    -o "$check_dir/policy-check"

DYLD_LIBRARY_PATH="$check_dir" "$check_dir/policy-check"
