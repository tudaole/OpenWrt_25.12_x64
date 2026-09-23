#!/bin/bash
set -e

echo "===== DIY2: OpenWrt 25.12 native configuration ====="

# OpenWrt 25.12 uses apk; remove obsolete opkg selections inherited
# from older configurations.
sed -i \
  -e '/^CONFIG_PACKAGE_opkg=y$/d' \
  -e '/^CONFIG_PACKAGE_luci-app-opkg=y$/d' \
  -e '/^CONFIG_PACKAGE_luci-lib-ipkg=y$/d' \
  .config

# Fix the confirmed OpenWrt 25.12 + Netdata package-install conflict.
# netdata owns /etc/netdata/netdata.conf, so do not let another package
# (notably base-files in the current build) provide the same file.
find package -path '*/files/etc/netdata/netdata.conf' -delete

make defconfig

echo "DIY2 completed."
