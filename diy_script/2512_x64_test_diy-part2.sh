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
grep -q '^net.netfilter.nf_conntrack_max=' "$SYSCTL_FILE" 2>/dev/null ||     echo 'net.netfilter.nf_conntrack_max=65535' >> "$SYSCTL_FILE"

# ttyd 免账号登录
if [ -f feeds/packages/utils/ttyd/files/ttyd.config ]; then
    sed -i 's#/bin/login#/bin/login -f root#' feeds/packages/utils/ttyd/files/ttyd.config
fi

# x86 型号只显示 CPU 型号
AUTOCORE_FILE=""
for f in     package/autocore/files/x86/autocore     feeds/packages/utils/autocore/files/x86/autocore     package/autocore/files/x86/autocore.lua; do
    if [ -f "$f" ]; then
        AUTOCORE_FILE="$f"
        break
    fi
done

if [ -n "$AUTOCORE_FILE" ]; then
    sed -i 's/${g}.*/${a}${b}${c}${d}${e}${f}${hydrid}/g' "$AUTOCORE_FILE" || true
fi

# 设置 Argon 为默认主题
find feeds/luci/themes -type f -path '*/uci-defaults/*' -exec     sed -i '/set luci.main.mediaurlbase=\/luci-static\/bootstrap/d' {} + 2>/dev/null || true

# 修改Argon主题的右下角脚本版本信息和登录页版本信息
cp -f $GITHUB_WORKSPACE/personal/argon/footer.ut package/luci-theme-argon/ucode/template/themes/argon/footer.ut
cp -f $GITHUB_WORKSPACE/personal/argon/footer_login.ut package/luci-theme-argon/ucode/template/themes/argon/footer_login.ut
sed -i "s/OpenWrt_2512_x64_build_name by GXNAS build @R build_date/OpenWrt_2512_x64_${build_name} by GXNAS build @R${build_date}/g" \
package/luci-theme-argon/ucode/template/themes/argon/footer.ut \
package/luci-theme-argon/ucode/template/themes/argon/footer_login.ut

# 修改Liquid主题的右下角脚本版本信息和登录页版本信息
cp -f $GITHUB_WORKSPACE/personal/liquid/footer.ut package/luci-theme-liquid/ucode/template/themes/liquid/footer.ut
sed -i "s/OpenWrt_2512_x64_build_name by GXNAS build @R build_date/OpenWrt_2512_x64_${build_name} by GXNAS build @R${build_date}/g" \
package/luci-theme-liquid/ucode/template/themes/liquid/footer.ut

# 自定义 banner
cp -f "$GITHUB_WORKSPACE/personal/banner" package/base-files/files/etc/banner

# 处理 openwrt.org 的第三方 Makefile。
find package -type f \( -name "Makefile" -o -name "*.mk" \)     -exec sed -i 's#https://git.openwrt.org/#https://github.com/openwrt/#g' {} + 2>/dev/null || true

# ============================================================
# OpenWrt 25.12：PassWall2 / SSR Plus 使用 iptables-nft
# ============================================================

echo "============修正 PassWall2 / SSR Plus 的 iptables 依赖============"

# ------------------------------------------------------------
# 自动查找 PassWall2
# ------------------------------------------------------------

PASSWALL2_MK=$(find feeds package -type f \
    -path '*/luci-app-passwall2/Makefile' \
    -print -quit 2>/dev/null || true)

if [ -n "$PASSWALL2_MK" ] && [ -f "$PASSWALL2_MK" ]; then

    echo "找到 PassWall2：$PASSWALL2_MK"

    # 删除 legacy 依赖
    sed -i '/^[[:space:]]*select PACKAGE_iptables-zz-legacy$/d' "$PASSWALL2_MK"
    sed -i '/^[[:space:]]*select PACKAGE_ip6tables-zz-legacy$/d' "$PASSWALL2_MK"

    # 删除未指定 variant 的 iptables
    sed -i '/^[[:space:]]*select PACKAGE_iptables$/d' "$PASSWALL2_MK"
    sed -i '/^[[:space:]]*select PACKAGE_ip6tables$/d' "$PASSWALL2_MK"

    # 确保使用 nft
    if ! grep -q 'select PACKAGE_iptables-nft' "$PASSWALL2_MK"; then
        sed -i '/select PACKAGE_ipset$/a\	select PACKAGE_iptables-nft' "$PASSWALL2_MK"
    fi

    if ! grep -q 'select PACKAGE_ip6tables-nft' "$PASSWALL2_MK"; then
        sed -i '/select PACKAGE_iptables-nft$/a\	select PACKAGE_ip6tables-nft' "$PASSWALL2_MK"
    fi

    echo "PassWall2: 已切换为 iptables-nft / ip6tables-nft"

else

    echo "未找到 luci-app-passwall2/Makefile"

fi


# ------------------------------------------------------------
# 自动查找 SSR Plus
# ------------------------------------------------------------

SSRPLUS_MK=$(find feeds package -type f \
    -path '*/luci-app-ssr-plus/Makefile' \
    -print -quit 2>/dev/null || true)

if [ -n "$SSRPLUS_MK" ] && [ -f "$SSRPLUS_MK" ]; then

    echo "找到 SSR Plus：$SSRPLUS_MK"

    # 删除 legacy 依赖
    sed -i '/^[[:space:]]*select PACKAGE_iptables-zz-legacy$/d' "$SSRPLUS_MK"
    sed -i '/^[[:space:]]*select PACKAGE_ip6tables-zz-legacy$/d' "$SSRPLUS_MK"

    # 删除未指定 variant 的 iptables
    sed -i '/^[[:space:]]*select PACKAGE_iptables$/d' "$SSRPLUS_MK"
    sed -i '/^[[:space:]]*select PACKAGE_ip6tables$/d' "$SSRPLUS_MK"

    # 确保使用 nft
    if ! grep -q 'select PACKAGE_iptables-nft' "$SSRPLUS_MK"; then
        sed -i '/select PACKAGE_ipset$/a\	select PACKAGE_iptables-nft' "$SSRPLUS_MK"
    fi

    if ! grep -q 'select PACKAGE_ip6tables-nft' "$SSRPLUS_MK"; then
        sed -i '/select PACKAGE_iptables-nft$/a\	select PACKAGE_ip6tables-nft' "$SSRPLUS_MK"
    fi

    echo "SSR Plus: 已切换为 iptables-nft / ip6tables-nft"

else

    echo "未找到 luci-app-ssr-plus/Makefile"

fi


# ------------------------------------------------------------
# 修改 .config
# ------------------------------------------------------------

if [ -f ".config" ]; then

    echo "============修正 .config 的 iptables variant============"

    # 禁用 legacy
    sed -i \
        's/^CONFIG_PACKAGE_iptables-zz-legacy=y$/# CONFIG_PACKAGE_iptables-zz-legacy is not set/' \
        .config

    sed -i \
        's/^CONFIG_PACKAGE_ip6tables-zz-legacy=y$/# CONFIG_PACKAGE_ip6tables-zz-legacy is not set/' \
        .config

    # 启用 nft
    if grep -q '^# CONFIG_PACKAGE_iptables-nft is not set$' .config; then
        sed -i \
            's/^# CONFIG_PACKAGE_iptables-nft is not set$/CONFIG_PACKAGE_iptables-nft=y/' \
            .config
    elif ! grep -q '^CONFIG_PACKAGE_iptables-nft=y$' .config; then
        echo 'CONFIG_PACKAGE_iptables-nft=y' >> .config
    fi

    if grep -q '^# CONFIG_PACKAGE_ip6tables-nft is not set$' .config; then
        sed -i \
            's/^# CONFIG_PACKAGE_ip6tables-nft is not set$/CONFIG_PACKAGE_ip6tables-nft=y/' \
            .config
    elif ! grep -q '^CONFIG_PACKAGE_ip6tables-nft=y$' .config; then
        echo 'CONFIG_PACKAGE_ip6tables-nft=y' >> .config
    fi

    echo "iptables-nft: 已启用"
    echo "ip6tables-nft: 已启用"
    echo "iptables-zz-legacy: 已禁用"
    echo "ip6tables-zz-legacy: 已禁用"

fi
echo "=============iptables 依赖修正完成============"

echo "=============DIY2 配置完成============"
