#!/bin/bash
set -e

echo "===== DIY1: OpenWrt 25.12 native preparation ====="

mkdir -p package/base-files/files/etc/uci-defaults

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
