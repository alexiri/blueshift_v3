#!/usr/bin/env bash

set -euo pipefail
set -x

echo "ostreecontainer --url ghcr.io/alexiri/blueshift_v3:10" \
    >> /almalinux-desktop-bootc.ks

rm -f /pwd/AlmaLinux-10-${VARIANT}-bootc-latest-beta-${ARCH}-boot.iso

dnf install -y \
    lorax

mkksiso \
    --ks /almalinux-desktop-bootc.ks \
    /pwd/AlmaLinux-10-latest-beta-${ARCH}-boot.iso \
    /pwd/AlmaLinux-10-${VARIANT}-bootc-latest-beta-${ARCH}-boot.iso
