#!/bin/sh
set -e

# Check and extract version number
[ $# != 1 ] && echo "Usage:  $0 <latest_releases_tag>" && exit 1
VERSION=$(echo "$1" | sed -n 's|[^0-9]*\([^_]*\).*|\1|p') && test "$VERSION"

PACKAGE=neovide
REPO=neovide/neovide

ARCH_LIST="amd64"
AMD64_FILENAME=neovide-linux-x86_64.tar.gz

prepare() {
    mkdir -p output tmp
    curl -fs "https://raw.githubusercontent.com/sigoden/dufs/refs/heads/main/CHANGELOG.md" | gzip > tmp/changelog.gz
    curl -fsLo "tmp/$PACKAGE.png" https://github.com/neovide/neovide/raw/refs/heads/main/assets/neovide.svg
    curl -fsLo "tmp/$PACKAGE.desktop" https://github.com/neovide/neovide/raw/refs/heads/main/assets/neovide.desktop
    sed -i "s/Icon=neovide/Icon=$PACKAGE/" "tmp/$PACKAGE.desktop"
    sed -i "s/Exec=neovide/Exec=$PACKAGE/" "tmp/$PACKAGE.desktop"
}

build() {
    BASE_DIR="$PACKAGE"_"$ARCH" && rm -rf "$BASE_DIR"
    install -D templates/copyright -t "$BASE_DIR/usr/share/doc/$PACKAGE"
    install -D tmp/changelog.gz -t "$BASE_DIR/usr/share/doc/$PACKAGE"

    # Download and move file
    curl -fsLo "tmp/$PACKAGE-$ARCH.tar.gz" "$(get_url_by_arch "$ARCH")"
    tar -xf "tmp/$PACKAGE-$ARCH.tar.gz"
    install -D -m 755 -t "$BASE_DIR/usr/bin" neovide && rm neovide

    install -D "tmp/$PACKAGE.desktop" -t "$BASE_DIR/usr/share/applications"
    install -D "tmp/$PACKAGE.png" -t "$BASE_DIR/usr/share/icons/hicolor/scalable/apps"

    # Package deb
    mkdir -p "$BASE_DIR/DEBIAN"
    SIZE=$(du -sk "$BASE_DIR"/usr | cut -f1)
    echo "Package: $PACKAGE
Version: $VERSION-1
Architecture: $ARCH
Installed-Size: $SIZE
Maintainer: wcbing <i@wcbing.top>
Section: editors
Priority: optional
Depends: neovim
Homepage: https://github.com/$REPO
Description: This is a simple graphical user interface for Neovim
 (an aggressively refactored and updated Vim editor). 
 Where possible there are some graphical improvements, but functionally
 it should act like the terminal UI.
 To checkout all the cool features, installation instructions,
 configuration settings and much more, head on over to neovide.dev.
" > "$BASE_DIR/DEBIAN/control"

    dpkg-deb -b --root-owner-group -Z xz "$BASE_DIR" output
}

get_url_by_arch() {
    DOWNLOAD_PREFIX="https://github.com/$REPO/releases/latest/download"
    case $1 in
    "amd64") echo "$DOWNLOAD_PREFIX/$AMD64_FILENAME" ;;
    esac
}

prepare

for ARCH in $ARCH_LIST; do
    echo "Building $ARCH package..."
    build
done

# Create repo files
cd output && apt-ftparchive packages . > Packages && apt-ftparchive release . > Release
