#!/bin/bash
# Packages specified directories with font files into .deb packages.
# Usage: ./package-fonts.sh [dir1 [dir2 ...]]
# Creates fonts-<dir>_<version>_all.deb for each directory.
# Version inferred from directory name or set to 0.0.YYYYMMDD.

set -e -o pipefail

package_dir() {
  input_dir="$1"
  if ! [[ -d "$input_dir" ]]; then
    echo "Error: $input_dir is not a directory"
    exit 1
  fi

  pkg_name="fonts-$(basename "$input_dir")"
  pkg_version="0.0.$(date +%Y%m%d)"

  if [[ "$pkg_name" =~ (.*)-([0-9]+\.[0-9.]+)$ ]]; then
    pkg_name="${BASH_REMATCH[1]}"
    pkg_version="${BASH_REMATCH[2]}"
  fi

  pkg_deb="${pkg_name}_${pkg_version}_all.deb"

  tmp="$(mktemp -d)"

  gen() {
    echo "Section: dotfiles
Priority: optional
Standards-Version: 4.3.0

Package: ${pkg_name}
Version: ${pkg_version}
Maintainer: none
Architecture: all
Description: Fonts
Copyright: $tmp/copyright
Readme: $tmp/readme"

    echo -n "Files:"
    for extdir in ttf:truetype otf:opentype eot:eot woff:woff woff2:woff; do
      ext="${extdir%:*}"
      subdir="${extdir#*:}"
      find "${input_dir}/" -type f -name "*.$ext" | (
        while read src; do
          echo " $src /usr/share/fonts/$subdir/${pkg_name#fonts-}/";
        done)
    done

    find "${input_dir}/" -type f \
      '(' -iname "copyright*" -or -iname "license*" -or -iname "licence*" -or -iname "authors*" -or -iname "copying*" ')' \
      -exec cat '{}' ';' >"$tmp/copyright"
    find "${input_dir}/" -type f '(' -iname "readme*" -or -name 'OFL.txt' ')' \
      -exec cat '{}' ';' >"$tmp/readme"
  }

  gen >"$tmp/control"

  if ! egrep -q 'Files: .*(ttf|otf|eot|woff|woff2) /usr/' "$tmp/control"; then
    echo "No font files found in $dir"
    exit 1
  fi

  echo "Packaging ${input_dir}/ into ${pkg_deb}"

  rm -f "${pkg_deb} ${pkg_name}.log"
  equivs-build "$tmp/control" >"${pkg_name}.log" 2>&1

  if [[ $? != 0 || ! -f "${pkg_deb}" ]]; then
    echo "Build of ${pkg_name} failed, see ${pkg_name}.log"
    exit 1
  fi

  rm -rf "$tmp" "${pkg_name}.log"
}


if [[ $# == 0 ]]; then
  head ${BASH_SOURCE[0]} | grep '^# ' | sed -e 's/^# *//'
  exit
fi

if [[ $# == 1 ]]; then
  package_dir "$1"
else
  for dir in "$@"; do
    (package_dir "$dir") &
  done
  wait
fi
