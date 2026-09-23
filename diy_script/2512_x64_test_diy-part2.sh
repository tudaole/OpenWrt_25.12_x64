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

# 官方 OpenWrt 没有 LEDE 的 package/lean/default-settings。
# 使用 uci-defaults 在首次启动时完成默认设置。

mkdir -p package/base-files/files/etc/uci-defaults

cat > package/base-files/files/etc/uci-defaults/99-gxnas-system <<'EOF'
#!/bin/sh

# 主机名、时区、NTP
uci set system.@system[0].hostname='OpenWrt-GXNAS'
uci set system.@system[0].zonename='Asia/Shanghai'
uci set system.@system[0].timezone='CST-8'

uci -q delete system.ntp.server
uci add_list system.ntp.server='ntp.aliyun.com'
uci add_list system.ntp.server='time1.cloud.tencent.com'
uci add_list system.ntp.server='time.apple.com'
uci add_list system.ntp.server='time.windows.com'

# LuCI 默认中文
uci set luci.main.lang='zh_cn'

# Argon 默认主题
uci set luci.main.mediaurlbase='/luci-static/argon'

uci commit system
uci commit luci
exit 0
EOF
chmod +x package/base-files/files/etc/uci-defaults/99-gxnas-system

# 首次启动删除 root 密码，达到“无需密码首次登录”的效果。
# 登录后请立即设置新密码。
cat > package/base-files/files/etc/uci-defaults/98-gxnas-password <<'EOF'
#!/bin/sh
passwd -d root >/dev/null 2>&1 || true
exit 0
EOF
chmod +x package/base-files/files/etc/uci-defaults/98-gxnas-password

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

# Argon：取消 Bootstrap 的默认主题设置。
# 不再修改 package/lean 或 feeds/luci/collections 中的 LEDE 路径，
# 直接通过 99-gxnas-system 设置 mediaurlbase。
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

# Netdata 服务修复
if [ -f package/luci-app-netdata/root/etc/init.d/netdata ]; then
    chmod +x package/luci-app-netdata/root/etc/init.d/netdata
    mkdir -p package/base-files/files/etc/rc.d
    ln -sf ../init.d/netdata package/base-files/files/etc/rc.d/S99netdata
fi

mkdir -p package/base-files/files/etc/netdata
cat > package/base-files/files/etc/netdata/netdata.conf <<'EOF'
[global]
    run as user = root
    memory mode = ram
[cloud]
    enabled = no
EOF

cat > package/base-files/files/etc/uci-defaults/99-netdata <<'EOF'
#!/bin/sh
if [ -x /etc/init.d/netdata ]; then
    /etc/init.d/netdata enable
    /etc/init.d/netdata restart
fi
exit 0
EOF
chmod +x package/base-files/files/etc/uci-defaults/99-netdata

# 官方仓库已经使用 GitHub/openwrt-25.12 feed。
# 这里只处理仍写死 git.openwrt.org 的第三方 Makefile。
find package -type f \( -name "Makefile" -o -name "*.mk" \)     -exec sed -i 's#https://git.openwrt.org/#https://github.com/openwrt/#g' {} + 2>/dev/null || true

# 移除旧 LEDE 默认设置/UPnP 删除逻辑：官方 OpenWrt 不存在这些文件，
# 不要用 find/xargs 去修改整个 package tree，以免误删新版依赖。

echo "========================="
echo " DIY2 配置完成……"
