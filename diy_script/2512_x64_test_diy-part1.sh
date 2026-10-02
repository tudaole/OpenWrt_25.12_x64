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

# Vlmcsd 插件
rm -rf package/luci-app-vlmcsd
git clone --depth=1 https://github.com/N7777777/luci-app-vlmcsd.git package/luci-app-vlmcsd

# 修复 vlmcsd Makefile（下载地址 + 安装路径）
cat > package/luci-app-vlmcsd/vlmcsd/Makefile << 'EOF'
include $(TOPDIR)/rules.mk
PKG_NAME:=vlmcsd
PKG_VERSION:=svn1113
PKG_RELEASE:=1
PKG_SOURCE:=vlmcsd-$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=https://codeload.github.com/Wind4/vlmcsd/tar.gz/refs/tags/$(PKG_VERSION)?
PKG_HASH:=skip
PKG_MAINTAINER:=nick <nick@example.com>
PKG_LICENSE:=MIT
include $(INCLUDE_DIR)/package.mk
define Package/vlmcsd
  SUBMENU:=Services
  SECTION:=utils
  CATEGORY:=Utilities
  TITLE:=KMS Server (vlmcsd)
endef
define Build/Compile
	$(MAKE) $(PKG_JOBS) -C $(PKG_BUILD_DIR) \
		CC="$(TARGET_CC)" \
		CFLAGS="$(TARGET_CFLAGS)" \
		LDFLAGS="$(TARGET_LDFLAGS) -static"
endef
define Package/vlmcsd/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/bin/vlmcsd $(1)/usr/bin/vlmcsd
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/vlmcsd.init $(1)/etc/init.d/vlmcsd
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_DATA) ./files/vlmcsd.uci $(1)/etc/config/vlmcsd
	$(INSTALL_DIR) $(1)/etc
	touch $(1)/etc/vlmcsd.ini
endef
$(eval $(call BuildPackage,vlmcsd))
EOF


echo "=============DIY1 配置完成============"
