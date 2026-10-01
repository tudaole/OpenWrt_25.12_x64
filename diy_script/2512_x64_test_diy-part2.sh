#!/bin/bash
#
# OpenWrt DIY script part 2 (After Update feeds)
# Adapted for official openwrt/openwrt v25.12.
#

set -e

echo "============开始 DIY2 配置============="

build_date=$(TZ=Asia/Shanghai date "+%Y.%m.%d")
build_name="测试版"

# 默认 LAN 地址
sed -i 's/192.168.1.1/192.168.1.11/g' package/base-files/files/bin/config_generate

# 最大连接数
SYSCTL_FILE="package/base-files/files/etc/sysctl.conf"
grep -q '^net.netfilter.nf_conntrack_max=' "$SYSCTL_FILE" 2>/dev/null || \
    echo 'net.netfilter.nf_conntrack_max=65535' >> "$SYSCTL_FILE"

# ttyd 免账号登录
if [ -f feeds/packages/utils/ttyd/files/ttyd.config ]; then
    sed -i 's#/bin/login#/bin/login -f root#' feeds/packages/utils/ttyd/files/ttyd.config
fi

# x86 型号只显示 CPU 型号
AUTOCORE_FILE=""
for f in \
    package/autocore/files/x86/autocore \
    feeds/packages/utils/autocore/files/x86/autocore \
    package/autocore/files/x86/autocore.lua
do
    if [ -f "$f" ]; then
        AUTOCORE_FILE="$f"
        break
    fi
done

if [ -n "$AUTOCORE_FILE" ]; then
    sed -i 's/${g}.*/${a}${b}${c}${d}${e}${f}${hydrid}/g' "$AUTOCORE_FILE" || true
fi

# 设置 Argon 为默认主题（去掉 bootstrap 强制）
find feeds/luci/themes -type f -path '*/uci-defaults/*' -exec \
    sed -i '/set luci.main.mediaurlbase=\/luci-static\/bootstrap/d' {} + 2>/dev/null || true

# 修改 Argon 主题右下角 / 登录页版本信息
if [ -f "$GITHUB_WORKSPACE/personal/argon/footer.ut" ]; then
    cp -f "$GITHUB_WORKSPACE/personal/argon/footer.ut" \
        package/luci-theme-argon/ucode/template/themes/argon/footer.ut
fi
if [ -f "$GITHUB_WORKSPACE/personal/argon/footer_login.ut" ]; then
    cp -f "$GITHUB_WORKSPACE/personal/argon/footer_login.ut" \
        package/luci-theme-argon/ucode/template/themes/argon/footer_login.ut
fi
sed -i "s/OpenWrt_2512_x64_build_name by GXNAS build @R build_date/OpenWrt_2512_x64_${build_name} by GXNAS build @R${build_date}/g" \
    package/luci-theme-argon/ucode/template/themes/argon/footer.ut \
    package/luci-theme-argon/ucode/template/themes/argon/footer_login.ut \
    2>/dev/null || true

# 修改 Liquid 主题右下角版本信息
if [ -f "$GITHUB_WORKSPACE/personal/liquid/footer.ut" ]; then
    cp -f "$GITHUB_WORKSPACE/personal/liquid/footer.ut" \
        package/luci-theme-liquid/ucode/template/themes/liquid/footer.ut
fi
sed -i "s/OpenWrt_2512_x64_build_name by GXNAS build @R build_date/OpenWrt_2512_x64_${build_name} by GXNAS build @R${build_date}/g" \
    package/luci-theme-liquid/ucode/template/themes/liquid/footer.ut \
    2>/dev/null || true

# 自定义 banner
if [ -f "$GITHUB_WORKSPACE/personal/banner" ]; then
    cp -f "$GITHUB_WORKSPACE/personal/banner" package/base-files/files/etc/banner
fi

# 第三方 Makefile：git.openwrt.org -> github.com/openwrt
find package -type f \( -name "Makefile" -o -name "*.mk" \) \
    -exec sed -i 's#https://git.openwrt.org/#https://github.com/openwrt/#g' {} + 2>/dev/null || true

# ============================================================
# 彻底清除 iptables-zz-legacy，强制使用 nft
# ============================================================
echo "============彻底清除 iptables-zz-legacy select============"

find feeds package -type f -name 'Makefile' 2>/dev/null | while read -r mf; do
    [ -f "$mf" ] || continue
    sed -i \
        -e '/[[:space:]]*select[[:space:]]\+PACKAGE_iptables-zz-legacy/d' \
        -e '/[[:space:]]*select[[:space:]]\+PACKAGE_ip6tables-zz-legacy/d' \
        -e 's/select[[:space:]]\+PACKAGE_iptables$/select PACKAGE_iptables-nft/' \
        -e 's/select[[:space:]]\+PACKAGE_ip6tables$/select PACKAGE_ip6tables-nft/' \
        "$mf"
done

# 重点再修一次常见插件
for path in \
    feeds/helloworld/luci-app-ssr-plus/Makefile \
    package/feeds/helloworld/luci-app-ssr-plus/Makefile \
    feeds/passwall_luci/luci-app-passwall/Makefile \
    package/feeds/passwall_luci/luci-app-passwall/Makefile \
    feeds/passwall_luci/luci-app-passwall2/Makefile \
    package/feeds/passwall_luci/luci-app-passwall2/Makefile
do
    [ -f "$path" ] || continue
    echo "强制修补 iptables: $path"
    sed -i \
        -e '/[[:space:]]*select[[:space:]]\+PACKAGE_iptables-zz-legacy/d' \
        -e '/[[:space:]]*select[[:space:]]\+PACKAGE_ip6tables-zz-legacy/d' \
        -e 's/select[[:space:]]\+PACKAGE_iptables$/select PACKAGE_iptables-nft/' \
        -e 's/select[[:space:]]\+PACKAGE_ip6tables$/select PACKAGE_ip6tables-nft/' \
        "$path"
    if ! grep -q 'select PACKAGE_iptables-nft' "$path"; then
        sed -i '/select PACKAGE_ipset/a\	select PACKAGE_iptables-nft' "$path" 2>/dev/null || true
    fi
    if ! grep -q 'select PACKAGE_ip6tables-nft' "$path"; then
        sed -i '/select PACKAGE_iptables-nft/a\	select PACKAGE_ip6tables-nft' "$path" 2>/dev/null || true
    fi
done

# .config 强制
if [ -f ".config" ]; then
    echo "============修正 .config 的 iptables variant============"
    sed -i \
        -e 's/^CONFIG_PACKAGE_iptables-zz-legacy=y$/# CONFIG_PACKAGE_iptables-zz-legacy is not set/' \
        -e 's/^CONFIG_PACKAGE_ip6tables-zz-legacy=y$/# CONFIG_PACKAGE_ip6tables-zz-legacy is not set/' \
        -e 's/^# CONFIG_PACKAGE_iptables-nft is not set$/CONFIG_PACKAGE_iptables-nft=y/' \
        -e 's/^# CONFIG_PACKAGE_ip6tables-nft is not set$/CONFIG_PACKAGE_ip6tables-nft=y/' \
        .config
    grep -q '^CONFIG_PACKAGE_iptables-nft=y$' .config || echo 'CONFIG_PACKAGE_iptables-nft=y' >> .config
    grep -q '^CONFIG_PACKAGE_ip6tables-nft=y$' .config || echo 'CONFIG_PACKAGE_ip6tables-nft=y' >> .config
    grep -q 'iptables-zz-legacy is not set' .config || echo '# CONFIG_PACKAGE_iptables-zz-legacy is not set' >> .config
    grep -q 'ip6tables-zz-legacy is not set' .config || echo '# CONFIG_PACKAGE_ip6tables-zz-legacy is not set' >> .config
fi

echo "=============iptables 依赖修正完成============"

# ============================================================
# 修复 dns2socks：SourceForge SourceCode.zip 404
# 改用 GitHub codeload，使用实测 SHA256
# 源码路径：dns2socks-master/DNS2SOCKS/DNS2SOCKS.c
# ============================================================
echo "============修复 dns2socks 下载源============"

find feeds package -type f -path '*/dns2socks/Makefile' 2>/dev/null | while read -r DNS2SOCKS_MK; do
    [ -f "$DNS2SOCKS_MK" ] || continue
    echo "修补 dns2socks: $DNS2SOCKS_MK"

    cat > "$DNS2SOCKS_MK" << 'EOF'
include $(TOPDIR)/rules.mk

PKG_NAME:=dns2socks
PKG_VERSION:=2.1
PKG_RELEASE:=3

PKG_SOURCE:=dns2socks-2.1.tar.gz
# 末尾 ? 防止 download.pl 再拼接文件名
PKG_SOURCE_URL:=https://codeload.github.com/kongfl888/dns2socks/tar.gz/refs/heads/master?
# 实测 hash（kongfl888/dns2socks master 归档）；若上游更新导致校验失败再重新计算
PKG_HASH:=e0406637521cbec3560bf34857bc9e63fce6b494a07805c9d27c675175a08ee3

PKG_MAINTAINER:=ghostmaker
PKG_LICENSE:=BSD-3-Clause

PKG_BUILD_PARALLEL:=1

include $(INCLUDE_DIR)/package.mk

# codeload 解压目录名
PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-master

define Package/dns2socks
  SECTION:=net
  CATEGORY:=Network
  SUBMENU:=IP Addresses and Names
  TITLE:=DNS to SOCKS or HTTP proxy
  URL:=http://dns2socks.sourceforge.net/
  DEPENDS:=+libpthread
endef

define Package/dns2socks/description
  Resolve DNS requests via a SOCKS tunnel or HTTP proxy.
endef

define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
	gzip -dc $(DL_DIR)/$(PKG_SOURCE) | tar -C $(BUILD_DIR) -xf -
endef

define Build/Compile
	$(TARGET_CC) $(TARGET_CFLAGS) $(TARGET_CPPFLAGS) $(FPIC) \
		-o $(PKG_BUILD_DIR)/dns2socks \
		$(PKG_BUILD_DIR)/DNS2SOCKS/DNS2SOCKS.c \
		$(TARGET_LDFLAGS) -pthread
endef

define Package/dns2socks/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/dns2socks $(1)/usr/bin/dns2socks
endef

$(eval $(call BuildPackage,dns2socks))
EOF

    echo "dns2socks Makefile 已替换为 GitHub codeload 源（含真实 PKG_HASH）"
done

if ! find feeds package -type f -path '*/dns2socks/Makefile' 2>/dev/null | grep -q .; then
    echo "未找到 dns2socks/Makefile，跳过（可能未选 SSR 相关包）"
fi

echo "=============dns2socks 修复完成============"

echo "=============DIY2 配置完成============"
