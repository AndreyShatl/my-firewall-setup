#!/bin/bash
echo "=== ШАГ 3: КОПИРОВАНИЕ СЕТЕВЫХ КОНФИГОВ ==="

cd /opt/my-firewall-setup

echo "Копируем конфиг WireGuard..."
cp /etc/wireguard/wg0.conf etc/wireguard/ 2>/dev/null && echo "✅ wg0.conf" || echo "❌ wg0.conf не найден"

echo "Копируем правила nftables..."
cp /etc/nftables.conf etc/ 2>/dev/null && echo "✅ nftables.conf" || echo "❌ nftables.conf не найден"

echo "Копируем конфиг DHCP..."
cp /etc/dhcp/dhcpd.conf etc/dhcp/ 2>/dev/null && echo "✅ dhcpd.conf" || echo "❌ dhcpd.conf не найден"

echo "Копируем конфиг DNSmasq..."
cp /etc/dnsmasq.conf etc/ 2>/dev/null && echo "✅ dnsmasq.conf" || echo "❌ dnsmasq.conf не найден"

echo "✅ Сетевые конфиги скопированы"
