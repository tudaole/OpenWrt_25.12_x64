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

# 自定义 Argon 背景/页脚（文件存在时才覆盖）
if [ -f "$GITHUB_WORKSPACE/personal/bg1.jpg" ] &&    [ -d package/luci-theme-argon/htdocs/luci-static/argon/img ]; then
    cp -f "$GITHUB_WORKSPACE/personal/bg1.jpg"         package/luci-theme-argon/htdocs/luci-static/argon/img/bg1.jpg
fi

if [ -f "$GITHUB_WORKSPACE/personal/argon/footer.ut" ]; then
    cp -f "$GITHUB_WORKSPACE/personal/argon/footer.ut"         package/luci-theme-argon/ucode/template/themes/argon/footer.ut
fi

if [ -f "$GITHUB_WORKSPACE/personal/argon/footer_login.ut" ]; then
    cp -f "$GITHUB_WORKSPACE/personal/argon/footer_login.ut"         package/luci-theme-argon/ucode/template/themes/argon/footer_login.ut
fi

# 修改页脚中的旧版本名称（如果文件中存在）
find package/luci-theme-argon -type f \( -name 'footer.ut' -o -name 'footer_login.ut' \)     -exec sed -i "s/OpenWrt_2410_x64/OpenWrt_2512_x64/g; s/OpenWrt_2512_x64_build_name/OpenWrt_2512_x64_${build_name}/g; s/build_date/${build_date}/g" {} + 2>/dev/null || true

# 自定义 banner
if [ -f "$GITHUB_WORKSPACE/personal/banner" ]; then
    cp -f "$GITHUB_WORKSPACE/personal/banner" package/base-files/files/etc/banner
fi

# 处理 openwrt.org 的第三方 Makefile。
find package -type f \( -name "Makefile" -o -name "*.mk" \)     -exec sed -i 's#https://git.openwrt.org/#https://github.com/openwrt/#g' {} + 2>/dev/null || true

echo "========================="
echo " DIY2 配置完成……"
