#!/usr/bin/env bash
set -euo pipefail

usage() {
    cat << EOF
Usage: ${0##*/} [-d DIR] [-b REF] REPO [@REF]

Vendor a git repository by cloning it, optionally checking out a specific
ref, removing .git, and committing to the parent repository.

Options:
  -d DIR          Subdirectory name (default: extracted from repo URL)
  -b REF / @REF   Branch, tag, or commit to checkout
EOF
    exit "${1:-1}"
}

dir_name=""
ref=""

while getopts "d:b:" opt; do
    case "$opt" in
        d) dir_name="$OPTARG" ;;
        b) ref="$OPTARG" ;;
        *) usage ;;
    esac
done
shift $((OPTIND - 1))

(( $# < 1 )) && usage

git_url="$1"

# Support @REF syntax as alternative to -b flag
if [[ -n "${2:-}" ]] && [[ "$2" == @* ]]; then
    if [[ -z "$ref" ]]; then
        ref="${2#@}"
    fi
fi

# Extract directory name from URL if not provided
if [[ -z "$dir_name" ]]; then
    dir_name=$(basename "$git_url" .git)
fi

base_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
target_dir="${base_dir}/${dir_name}"

if [[ -d "$target_dir" ]]; then
    echo "Error: directory $target_dir already exists" >&2
    exit 1
fi

echo "Cloning $git_url into $target_dir"
if ! git clone "$git_url" "$target_dir"; then
    echo "Error: Failed to clone repository" >&2
    exit 1
fi

if [[ -n "$ref" ]]; then
    echo "Checking out $ref"
    if ! git -C "$target_dir" checkout "$ref"; then
        echo "Error: Failed to checkout $ref" >&2
        rm -rf "$target_dir"
        exit 1
    fi
fi

commit_sha=$(git -C "$target_dir" rev-parse HEAD)
echo "HEAD is at $commit_sha"

rm -rf "${target_dir}/.git"

parent_dir="$(cd "$base_dir/.." && pwd)"
relative_path="${target_dir#"$parent_dir"/}"

echo "Committing to parent repository"
git -C "$parent_dir" add "$relative_path"
git -C "$parent_dir" commit -m "${git_url} @${commit_sha}" "$relative_path"

echo "Vendored $git_url @$commit_sha into $relative_path"
