#!/bin/sh

PACKAGE="neovide"
REPO="neovide/neovide"

# Processing again to avoid errors of remote incoming 
VERSION=$(echo $1 | sed -n 's|[^0-9]*\([^_]*\).*|\1|p')

ARCH="amd64"
AMD64_FILENAME="neovide-linux-x86_64.tar.gz"
ARM64_FILENAME=""
build() {
    # Prepare
    BASE_DIR="$PACKAGE"_"$VERSION"-1_"$1"
    cp -r templates "$BASE_DIR"
    sed -i "s/Architecture: arch/Architecture: $1/" "$BASE_DIR/DEBIAN/control"
    sed -i "s/Version: version/Version: $VERSION-1/" "$BASE_DIR/DEBIAN/control"
    # Download and move file
    curl https://api.github.com/repos/$REPO/releases/latest | jq -r '.body' > $BASE_DIR/usr/share/doc/$PACKAGE/CHANGELOG.md
    curl -Lo $BASE_DIR/usr/share/applications/neovide.desktop https://github.com/neovide/neovide/raw/refs/heads/main/assets/neovide.desktop
    curl -Lo $BASE_DIR/usr/share/icons/hicolor/256x256/apps/neovide.png https://github.com/neovide/neovide/raw/main/assets/neovide-256x256.png
    curl -sLo "$PACKAGE-$VERSION-$1.tar.gz" "$(get_url_by_arch $1)"
    tar -xzf "$PACKAGE-$VERSION-$1.tar.gz"
    mv "$PACKAGE" "$BASE_DIR/usr/bin/$PACKAGE"
    chmod 755 "$BASE_DIR/usr/bin/$PACKAGE"
    # Build
    dpkg-deb -b --root-owner-group -Z xz "$BASE_DIR" output
}

get_url_by_arch() {
    case $1 in
    "amd64") echo "https://github.com/$REPO/releases/latest/download/$AMD64_FILENAME" ;;
    "arm64") echo "https://github.com/$REPO/releases/latest/download/$ARM64_FILENAME" ;;
    esac
}

mkdir output

for i in $ARCH; do
    echo "Building $i package..."
    build "$i"
done

# Create repo files
cd output
apt-ftparchive packages . > Packages
apt-ftparchive release . > Release
