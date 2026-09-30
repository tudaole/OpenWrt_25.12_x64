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
    package/autocore/files/x86/autocore.lua; do
    if [ -f "$f" ]; then
        AUTOCORE_FILE="$f"
        break
    fi
done

if [ -n "$AUTOCORE_FILE" ]; then
    sed -i 's/${g}.*/${a}${b}${c}${d}${e}${f}${hydrid}/g' "$AUTOCORE_FILE" || true
fi

# 设置 Argon 为默认主题
find feeds/luci/themes -type f -path '*/uci-defaults/*' -exec \
    sed -i '/set luci.main.mediaurlbase=\/luci-static\/bootstrap/d' {} + 2>/dev/null || true

# 修改 Argon 主题的右下角脚本版本信息和登录页版本信息
cp -f "$GITHUB_WORKSPACE/personal/argon/footer.ut" \
    package/luci-theme-argon/ucode/template/themes/argon/footer.ut

cp -f "$GITHUB_WORKSPACE/personal/argon/footer_login.ut" \
    package/luci-theme-argon/ucode/template/themes/argon/footer_login.ut

sed -i "s/OpenWrt_2512_x64_build_name by GXNAS build @R build_date/OpenWrt_2512_x64_${build_name} by GXNAS build @R${build_date}/g" \
    package/luci-theme-argon/ucode/template/themes/argon/footer.ut \
    package/luci-theme-argon/ucode/template/themes/argon/footer_login.ut

# 修改 Liquid 主题的右下角脚本版本信息和登录页版本信息
cp -f "$GITHUB_WORKSPACE/personal/liquid/footer.ut" \
    package/luci-theme-liquid/ucode/template/themes/liquid/footer.ut

sed -i "s/OpenWrt_2512_x64_build_name by GXNAS build @R build_date/OpenWrt_2512_x64_${build_name} by GXNAS build @R${build_date}/g" \
    package/luci-theme-liquid/ucode/template/themes/liquid/footer.ut

# 自定义 banner
cp -f "$GITHUB_WORKSPACE/personal/banner" package/base-files/files/etc/banner

# 处理 openwrt.org 的第三方 Makefile
find package -type f \( -name "Makefile" -o -name "*.mk" \) \
    -exec sed -i 's#https://git.openwrt.org/#https://github.com/openwrt/#g' {} + 2>/dev/null || true


# ============================================================
# OpenWrt 25.12：PassWall2 / SSR Plus 使用 iptables-nft
# 禁止第三方插件拉入 iptables-zz-legacy
# ============================================================

echo "============修正 PassWall2 / SSR Plus 的 iptables 依赖============"

# ------------------------------------------------------------
# PassWall2
# ------------------------------------------------------------
PASSWALL2_MK="feeds/luci/passwall2/luci-app-passwall2/Makefile"

if [ -f "$PASSWALL2_MK" ]; then

    # 删除 legacy iptables 依赖
    sed -i '/select PACKAGE_iptables-zz-legacy/d' "$PASSWALL2_MK"

    # 删除未指定 variant 的 iptables 依赖
    sed -i '/^[[:space:]]*select PACKAGE_iptables$/d' "$PASSWALL2_MK"

    # 确保使用 iptables-nft
    if ! grep -q 'select PACKAGE_iptables-nft' "$PASSWALL2_MK"; then
        sed -i '/select PACKAGE_ipset$/a\	select PACKAGE_iptables-nft' "$PASSWALL2_MK"
    fi

    echo "PassWall2: 已修改为使用 iptables-nft"

else
    echo "PassWall2 Makefile 未找到：$PASSWALL2_MK"
fi


# ------------------------------------------------------------
# SSR Plus / helloworld
# ------------------------------------------------------------
SSRPLUS_MK="feeds/helloworld/luci-app-ssr-plus/Makefile"

if [ -f "$SSRPLUS_MK" ]; then

    # 删除 legacy iptables 依赖
    sed -i '/select PACKAGE_iptables-zz-legacy/d' "$SSRPLUS_MK"

    # 删除未指定 variant 的 iptables 依赖
    sed -i '/^[[:space:]]*select PACKAGE_iptables$/d' "$SSRPLUS_MK"

    # 确保使用 iptables-nft
    if ! grep -q 'select PACKAGE_iptables-nft' "$SSRPLUS_MK"; then
        sed -i '/select PACKAGE_ipset$/a\	select PACKAGE_iptables-nft' "$SSRPLUS_MK"
    fi

    echo "SSR Plus: 已修改为使用 iptables-nft"

else
    echo "SSR Plus Makefile 未找到：$SSRPLUS_MK"
fi


# ------------------------------------------------------------
# .config 保险设置
# ------------------------------------------------------------
# 注意：这里只设置 iptables variant。
# firewall4 是否启用交给你现有的 2512_x64_test.config。
# ------------------------------------------------------------

if [ -x ./scripts/config ]; then

    ./scripts/config --enable PACKAGE_iptables-nft
    ./scripts/config --disable PACKAGE_iptables-zz-legacy

    echo "iptables-nft: 已启用"
    echo "iptables-zz-legacy: 已禁用"

else
    echo "警告：scripts/config 不存在，跳过 .config variant 设置"
fi


echo "=============PassWall2 / SSR Plus iptables 修正完成============"

echo "=============DIY2 配置完成============"
```
