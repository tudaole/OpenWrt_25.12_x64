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
src-git kms https://github.com/gaoderby/luci-app-kms.git;main
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

# MosDNS v5 插件
rm -rf feeds/packages/lang/golang
git clone --depth=1 https://github.com/sbwml/packages_lang_golang -b 26.x feeds/packages/lang/golang
rm -rf feeds/packages/net/v2ray-geodata
rm -rf package/mosdns package/v2ray-geodata
git clone --depth=1 https://github.com/sbwml/luci-app-mosdns -b v5 package/mosdns
git clone --depth=1 https://github.com/sbwml/v2ray-geodata package/v2ray-geodata

# OpenAppFilter 插件
rm -rf package/OpenAppFilter
git clone --depth=1 https://github.com/destan19/OpenAppFilter.git package/OpenAppFilter

# Poweroffdevice 插件
rm -rf package/luci-app-poweroffdevice
git clone --depth=1 https://github.com/sirpdboy/luci-app-poweroffdevice.git package/luci-app-poweroffdevice

# Turboacc 插件
rm -rf package/turboacc
curl -fsSL https://raw.githubusercontent.com/chenmozhijin/turboacc/luci/add_turboacc.sh -o /tmp/add_turboacc.sh
bash /tmp/add_turboacc.sh
rm -f /tmp/add_turboacc.sh

# ========== 修复 iStore 在 OpenWrt 25.12 (APK) 下的兼容性 ==========
echo "修复 istore Makefile 兼容性问题..."

# 1. 修复 luci-app-store 版本号（APK 不支持 0.2.1-r1 这种格式）
if [ -f feeds/istore/luci/luci-app-store/Makefile ]; then
    sed -i 's/PKG_VERSION:=0.2.1-r1/PKG_VERSION:=0.2.1/' feeds/istore/luci/luci-app-store/Makefile
    sed -i 's/^PKG_RELEASE:=$/PKG_RELEASE:=1/' feeds/istore/luci/luci-app-store/Makefile
    # 去掉可能有问题的版本约束
    sed -i 's/LUCI_EXTRA_DEPENDS:=luci-lib-taskd (>=1.0.19)/LUCI_EXTRA_DEPENDS:=luci-lib-taskd/' feeds/istore/luci/luci-app-store/Makefile
fi

# 2. 修复 luci-lib-taskd
if [ -f feeds/istore/luci/luci-lib-taskd/Makefile ]; then
    sed -i 's/LUCI_EXTRA_DEPENDS:=taskd (>=1.0.3)/LUCI_EXTRA_DEPENDS:=taskd/' feeds/istore/luci/luci-lib-taskd/Makefile
fi

# 3. 重新收集 package 信息（让修复生效）
./scripts/feeds install -d y -p istore luci-app-store

echo "istore 修复完成"


echo "=============DIY1 配置完成============"
