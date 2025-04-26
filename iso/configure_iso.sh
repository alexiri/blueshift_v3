#!/usr/bin/env bash

set -x

dnf config-manager --set-enabled crb

dnf install -y \
  anaconda \
  anaconda-install-env-deps \
  anaconda-live

systemctl --global disable podman-auto-update.timer
systemctl disable rpm-ostree.service
systemctl disable check-sb-key.service
