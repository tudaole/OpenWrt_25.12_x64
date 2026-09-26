#!/bin/bash
#
# OpenWrt DIY script part 2 (After Update feeds)
# Adapted for official openwrt/openwrt v25.12.
#

set -e

echo "开始 DIY2 配置……"
echo "========================="

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

# 显示增加编译时间
#sed -i "s/DISTRIB_REVISION='R[0-9]\+\.[0-9]\+\.[0-9]\+'/DISTRIB_REVISION='@R$build_date'/g" package/lean/default-settings/files/zzz-default-settings
#sed -i "s/LEDE/OpenWrt_2512_x64_${build_name} by GXNAS build/g" package/lean/default-settings/files/zzz-default-settings

# 修改Argon主题的右下角脚本版本信息和登录页版本信息
cp -f $GITHUB_WORKSPACE/personal/argon/footer.ut package/luci-theme-argon/ucode/template/themes/argon/footer.ut
cp -f $GITHUB_WORKSPACE/personal/argon/footer_login.ut package/luci-theme-argon/ucode/template/themes/argon/footer_login.ut
sed -i "s/OpenWrt_2512_x64_build_name by GXNAS build @R build_date/OpenWrt_2512_x64_${build_name} by GXNAS build @R${build_date}/g" \
package/luci-theme-argon/ucode/template/themes/argon/footer.ut \
package/luci-theme-argon/ucode/template/themes/argon/footer_login.ut

# 修改Liquid主题的右下角脚本版本信息和登录页版本信息
cp -f $GITHUB_WORKSPACE/personal/liquid/footer.ut package/luci-theme-liquid/ucode/template/themes/liquid/footer.ut
sed -i "s/OpenWrt_2512_x64_build_name by GXNAS build @R build_date/OpenWrt_2512_x64_${build_name} by GXNAS build @R${build_date}/g" \

# 自定义 banner
cp -f "$GITHUB_WORKSPACE/personal/banner" package/base-files/files/etc/banner

# 处理 openwrt.org 的第三方 Makefile。
find package -type f \( -name "Makefile" -o -name "*.mk" \)     -exec sed -i 's#https://git.openwrt.org/#https://github.com/openwrt/#g' {} + 2>/dev/null || true

echo "========================="
echo " DIY2 配置完成……"
