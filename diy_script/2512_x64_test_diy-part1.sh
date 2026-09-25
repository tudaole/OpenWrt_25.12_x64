#!/bin/bash
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
src-git openclaw https://github.com/10000ge10000/luci-app-openclaw.git;main
src-git istore https://github.com/gxnas/istore;main
EOF

# AdGuardHome
#rm -rf package/luci-app-adguardhome
#git clone --depth=1 https://github.com/kongfl888/luci-app-adguardhome package/luci-app-adguardhome

# Argon 主题
rm -rf package/luci-theme-argon package/luci-app-argon-config
git clone --depth=1 https://github.com/jerrykuku/luci-theme-argon.git package/luci-theme-argon
git clone --depth=1 https://github.com/jerrykuku/luci-app-argon-config.git package/luci-app-argon-config

# Lucky
rm -rf package/lucky
git clone --depth=1 https://github.com/gdy666/luci-app-lucky.git package/lucky

# OpenAppFilter
rm -rf package/OpenAppFilter
git clone --depth=1 https://github.com/destan19/OpenAppFilter.git package/OpenAppFilter

# Poweroffdevice
rm -rf package/luci-app-poweroffdevice
git clone --depth=1 https://github.com/sirpdboy/luci-app-poweroffdevice.git package/luci-app-poweroffdevice

# EasyTier
rm -rf package/luci-app-easytier
git clone --depth=1 https://github.com/EasyTier/luci-app-easytier.git package/luci-app-easytier

# iStore：保持使用 GXNAS 的中文适配仓库
sed -i '/^src-git istore /d' feeds.conf.default
echo 'src-git istore https://github.com/gxnas/istore;main' >> feeds.conf.default

# MosDNS v5
rm -rf feeds/packages/lang/golang
git clone --depth=1 https://github.com/sbwml/packages_lang_golang -b 26.x feeds/packages/lang/golang

rm -rf feeds/packages/net/v2ray-geodata
rm -rf package/mosdns package/v2ray-geodata
git clone --depth=1 https://github.com/sbwml/luci-app-mosdns -b v5 package/mosdns
git clone --depth=1 https://github.com/sbwml/v2ray-geodata package/v2ray-geodata

cat > package/base-files/files/etc/uci-defaults/99-gxnas-defaults <<'EOF'
#!/bin/sh
uci set system.@system[0].hostname='OpenWrt-GXNAS'
uci set system.@system[0].zonename='Asia/Shanghai'
uci set system.@system[0].timezone='CST-8'
uci commit system

uci set network.lan.ipaddr='192.168.1.11'
uci commit network

exit 0
EOF

chmod +x package/base-files/files/etc/uci-defaults/99-gxnas-defaults

echo "DIY1 completed."
