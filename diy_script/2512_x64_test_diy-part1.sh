#!/bin/bash
#
# OpenWrt DIY script part 1 (After Update feeds)
# Adapted for official openwrt/openwrt v25.12.
#

set -e

echo "===== DIY1: OpenWrt 25.12 native preparation ====="

mkdir -p package/base-files/files/etc/uci-defaults

# 第三方软件源
sed -i '/^src-git \(small\|helloworld\|passwall_packages\|passwall_luci\|openclaw\|istore\) /d' feeds.conf.default
cat >> feeds.conf.default <<'EOF'
src-git small https://github.com/kenzok8/small
src-git helloworld https://github.com/fw876/helloworld
src-git passwall_packages https://github.com/Openwrt-Passwall/openwrt-passwall-packages.git;main
src-git passwall_luci https://github.com/Openwrt-Passwall/openwrt-passwall.git;main
src-git istore https://github.com/gxnas/istore;main
EOF

# AdGuardHome 插件
rm -rf package/luci-app-adguardhome
git clone --depth=1 https://github.com/kongfl888/luci-app-adguardhome package/luci-app-adguardhome

# Argon 主题
rm -rf package/luci-theme-argon package/luci-app-argon-config
git clone --depth=1 https://github.com/jerrykuku/luci-theme-argon.git package/luci-theme-argon
git clone --depth=1 https://github.com/jerrykuku/luci-app-argon-config.git package/luci-app-argon-config

# EasyTier 插件
rm -rf package/luci-app-easytier
git clone --depth=1 https://github.com/EasyTier/luci-app-easytier.git package/luci-app-easytier

# Liquid 主题
git clone https://github.com/xylz0928/luci-theme-liquid.git package/luci-theme-liquid

# Lucky 插件
rm -rf package/lucky
git clone --depth=1 https://github.com/gdy666/luci-app-lucky.git package/lucky

# Netdata 插件
rm -rf package/luci-app-netdata
git clone --depth=1 https://github.com/sirpdboy/luci-app-netdata package/luci-app-netdata

# OpenAppFilter 插件
rm -rf package/OpenAppFilter
git clone --depth=1 https://github.com/destan19/OpenAppFilter.git package/OpenAppFilter

# Poweroffdevice 插件
rm -rf package/luci-app-poweroffdevice
git clone --depth=1 https://github.com/sirpdboy/luci-app-poweroffdevice.git package/luci-app-poweroffdevice

# MosDNS v5 插件
rm -rf feeds/packages/lang/golang
git clone --depth=1 https://github.com/sbwml/packages_lang_golang -b 26.x feeds/packages/lang/golang
rm -rf feeds/packages/net/v2ray-geodata
rm -rf package/mosdns package/v2ray-geodata
git clone --depth=1 https://github.com/sbwml/luci-app-mosdns -b v5 package/mosdns
git clone --depth=1 https://github.com/sbwml/v2ray-geodata package/v2ray-geodata

# turboacc 插件
rm -rf package/luci-app-turboacc
git clone --depth=1 https://github.com/chenmozhijin/turboacc.git package/luci-app-turboacc

echo "===== DIY1 completed. ====="
