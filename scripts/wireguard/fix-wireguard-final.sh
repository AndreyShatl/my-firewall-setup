#!/bin/bash
set -e

echo "=== ИСПРАВЛЕНИЕ WIREGUARD ==="

echo "🔧 Останавливаем WireGuard..."
systemctl stop wg-quick@wg0 2>/dev/null || true

echo "📋 Анализируем конфиг..."
# Проблема: в конфиге есть пиры без AllowedIPs
grep -n "PublicKey" /etc/wireguard/wg0.conf

echo ""
echo "🔄 Исправляем конфиг..."
# Создаем исправленный конфиг
cat > /etc/wireguard/wg0.conf << 'WG_EOF'
[Interface]
Address = 10.0.0.1/24
SaveConfig = true
PostUp = nft -f /etc/nftables.conf
PostUp = echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6
PostUp = echo 1 > /proc/sys/net/ipv6/conf/default/disable_ipv6
PostUp = echo 1 > /proc/sys/net/ipv6/conf/wg0/disable_ipv6
PostDown = nft delete table inet zapret 2>/dev/null || true
ListenPort = 51820
PrivateKey = +CVNATzjIqk0H5GydqKVfmjDe/Lrn2GDsbj7x7OGTVo=

[Peer]
PublicKey = Dipe1cnQnQCRa02Q/6qUxVUw+M3x5C9cWAWZir5BIhM=
AllowedIPs = 10.0.0.2/32

[Peer]
PublicKey = O8BC+VktsIiH1rC4RdPstP8uRxiCKHa93aXk+8eMtQ4=
AllowedIPs = 10.0.0.3/32
Endpoint = 87.245.179.85:45372

[Peer]
PublicKey = u00oaxWEguwV/NbQGfAcWc5sYHuq4VPVydMFTjB90QE=
AllowedIPs = 10.0.0.4/32
WG_EOF

echo ""
echo "✅ Исправленный конфиг:"
cat /etc/wireguard/wg0.conf

echo ""
echo "🚀 Запускаем WireGuard..."
wg-quick up wg0

echo ""
echo "⏳ Ждем 3 секунды..."
sleep 3

echo ""
echo "🔍 Проверяем статус..."
systemctl status wg-quick@wg0 --no-pager -l

echo ""
echo "🌐 Проверяем интерфейс..."
ip addr show wg0 2>/dev/null && echo "✅ WG0 запущен" || echo "❌ WG0 не запущен"
wg show

echo ""
echo "📊 Проверяем правила nftables..."
nft list ruleset | grep -A5 "queue to"

echo ""
echo "✅ Исправление завершено!"
