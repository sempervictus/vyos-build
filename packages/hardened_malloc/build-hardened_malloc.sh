#!/bin/sh

# Build libhardened_malloc package from Whonix repo
set -e
sudo apt install -y dh-exec clang llvm-dev clang-tidy
REPO="https://github.com/Whonix/hardened_malloc"
test ! -d hardened_malloc && git clone "$REPO"
cd hardened_malloc
echo "I: Build Debian Hardened Malloc Package"
dpkg-buildpackage -b -rfakeroot -us -uc
cd ..
mv hardened-malloc_*deb ..
rm hardened-* -rf
