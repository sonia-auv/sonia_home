#!/usr/bin/env bash

sonia_build() {
    local use_dir=0
    local use_cache=0
    local path="$PWD"
    local folder
    folder=$(basename "$PWD")

    # Parse flags (can combine -d and -c)
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -d|--dir)   use_dir=1 ;;
            -c|--cache) use_cache=1 ;;
            -h|--help)
                cat <<EOF
Usage: sonia_build_all [options]

Options (can be combined):
  -d, --dir     Build all packages under the current directory path
                (uses --paths "<cwd>/*", auto-adds --allow-overriding for found packages)
  -c, --cache   Clean CMake cache before building (--cmake-clean-cache)
  -h, --help    Show this help

Default (no flags): build only the current package (same as old 'sonia_build').

Examples:
  sonia_build_all
      Build current package.
  sonia_build_all -c
      Build current package, cleaning cache.
  sonia_build_all -d
      Build all packages under the current directory path.
  sonia_build_all -d -c
      Build all packages under the current directory path, cleaning cache.

Requires:
  SONIA_WS to be set to your ROS 2 workspace root.
EOF
                return 0
                ;;
            *)
                echo "Unknown option: $1"
                echo "Try: sonia_build_all -h"
                return 2
                ;;
        esac
        shift
    done

    if [ -z "$SONIA_WS" ] || [ ! -d "$SONIA_WS" ]; then
        echo "Error: SONIA_WS not set or not a directory"
        return 1
    fi

    # Helper: extract package name from package.xml
    _sb_pkgname_from_xml() {
        sed -n 's:.*<name>[[:space:]]*\([^<[:space:]]\+\)[[:space:]]*</name>.*:\1:p' "$1" | head -n1
    }

    # Detect current package name for normal/cache modes
    local pkg="$folder"
    if [ -f "$path/package.xml" ]; then
        local detected
        detected=$(_sb_pkgname_from_xml "$path/package.xml")
        [ -n "$detected" ] && pkg="$detected"
    fi

    cd "$SONIA_WS" || return 1

    # Build base command
    local base_cmd=(colcon build --symlink-install --cmake-args -DCMAKE_EXPORT_COMPILE_COMMANDS=ON)
    if (( use_cache )); then
        base_cmd+=("--cmake-clean-cache")
    fi

    if (( use_dir )); then
        # DIR mode: collect package names under $path/*
        local pkgs=()
        local d pkgxml pkgname
        for d in "$path"/*/ ; do
            [ -d "$d" ] || continue
            pkgxml="$d/package.xml"
            [ -f "$pkgxml" ] || continue
            pkgname=$(_sb_pkgname_from_xml "$pkgxml")
            [ -n "$pkgname" ] && pkgs+=("$pkgname")
        done

        if [ "${#pkgs[@]}" -eq 0 ]; then
            echo "Warning: no ROS 2 packages found under $path/*"
            "${base_cmd[@]}" --continue-on-error --paths "$path"/*
        else
            "${base_cmd[@]}" --continue-on-error --paths "$path"/* --allow-overriding "${pkgs[@]}"
        fi
    else
        # NORMAL/CACHE mode: single package
        "${base_cmd[@]}" --packages-select "$pkg" --allow-overriding "$pkg"
    fi

    cd "$path" || return
}
