#!/bin/bash
set -e

echo "===== DIY2: OpenWrt 25.12 native configuration ====="

# OpenWrt 25.12 uses apk; remove obsolete opkg selections inherited from
# older configurations.
sed -i \
  -e '/^CONFIG_PACKAGE_opkg=y$/d' \
  -e '/^CONFIG_PACKAGE_luci-app-opkg=y$/d' \
  -e '/^CONFIG_PACKAGE_luci-lib-ipkg=y$/d' \
  .config

# Do not force-remove third-party packages here. Their missing dependency
# warnings are reported by OpenWrt and can be addressed individually later.

make defconfig

echo "DIY2 completed."
