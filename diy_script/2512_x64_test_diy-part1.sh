#!/bin/bash
#
# OpenWrt DIY script part 1 (After Update feeds)
# Adapted for official openwrt/openwrt v25.12.
#

set -e

echo "============开始 DIY1 配置============="

mkdir -p package/base-files/files/etc/uci-defaults

# 第三方软件源（官方 OpenWrt 25.12 推荐）
sed -i '/^src-git \(small\|helloworld\|passwall_packages\|passwall_luci\|openclaw\|istore\) /d' feeds.conf.default
cat >> feeds.conf.default <<'EOF'
src-git passwall_packages https://github.com/Openwrt-Passwall/openwrt-passwall-packages.git;main
src-git passwall_luci https://github.com/Openwrt-Passwall/openwrt-passwall.git;main
src-git istore https://github.com/linkease/istore;main
EOF

# Argon 主题
rm -rf package/luci-theme-argon package/luci-app-argon-config
git clone --depth=1 https://github.com/jerrykuku/luci-theme-argon.git package/luci-theme-argon
git clone --depth=1 https://github.com/jerrykuku/luci-app-argon-config.git package/luci-app-argon-config

# Liquid 主题
git clone https://github.com/xylz0928/luci-theme-liquid.git package/luci-theme-liquid


echo "=============DIY1 配置完成============"
