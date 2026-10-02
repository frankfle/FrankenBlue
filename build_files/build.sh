#!/bin/bash

set -ouex pipefail

# Copy the contents of system_files/ of the git repo to /
cp -avf "/ctx/system_files"/. /

### Install packages

# Packages can be installed from any enabled yum repo on the image.
# RPMfusion repos are available by default in ublue main images.
# List of rpmfusion packages can be found here:
# https://mirrors.rpmfusion.org/mirrorlist?path=free/fedora/updates/44/x86_64/repoview/index.html&protocol=https&redirect=1

# General CLI / developer tools
dnf5 install -y \
    ripgrep \
    fd-find \
    eza \
    bat \
    zoxide \
    fzf \
    atuin \
    procs \
    du-dust

# starship is not packaged in Fedora or RPM Fusion, so install a pinned
# release binary. The .sha256 sidecar from the release is verified first.
STARSHIP_VERSION="1.26.0"
case "$(uname -m)" in
    x86_64)   STARSHIP_ARCH="x86_64" ;;
    aarch64)  STARSHIP_ARCH="aarch64" ;;
    *) echo "Unsupported arch for starship: $(uname -m)" >&2; exit 1 ;;
esac
STARSHIP_TARBALL="starship-${STARSHIP_ARCH}-unknown-linux-musl.tar.gz"
STARSHIP_URL="https://github.com/starship/starship/releases/download/v${STARSHIP_VERSION}"
curl -fsSL -o "/tmp/${STARSHIP_TARBALL}" "${STARSHIP_URL}/${STARSHIP_TARBALL}"
curl -fsSL -o "/tmp/${STARSHIP_TARBALL}.sha256" "${STARSHIP_URL}/${STARSHIP_TARBALL}.sha256"
# the .sha256 sidecar contains only the hash, no filename
STARSHIP_SHA256="$(tr -d ' \t\r\n' < "/tmp/${STARSHIP_TARBALL}.sha256")"
( cd /tmp && echo "${STARSHIP_SHA256}  ${STARSHIP_TARBALL}" | sha256sum -c - )
# the tarball contains a single "starship" binary at its root
tar xzf "/tmp/${STARSHIP_TARBALL}" -C /tmp
install -m755 /tmp/starship /usr/bin/starship
rm -f "/tmp/${STARSHIP_TARBALL}" "/tmp/${STARSHIP_TARBALL}.sha256" /tmp/starship

### Branding

# ostree writes bootloader entry titles from PRETTY_NAME in
# /usr/lib/os-release, which we inherit from the Bazzite base. Rewrite the
# name fields so deployments of this image are labelled FrankenBlue.
# ID and VARIANT_ID are left as-is so UBlue update/variant tooling keeps
# working on this derived image.
sed -i 's/^PRETTY_NAME=.*/PRETTY_NAME="FrankenBlue"/' /usr/lib/os-release
sed -i 's/^NAME=.*/NAME="FrankenBlue"/' /usr/lib/os-release

# Use a COPR Example:
#
# dnf5 -y copr enable ublue-os/staging
# dnf5 -y install package
# Disable COPRs so they don't end up enabled on the final image:
# dnf5 -y copr disable ublue-os/staging

# Example for enabling a System Unit File:
# systemctl enable some-service.socket
