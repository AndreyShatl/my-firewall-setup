#!/bin/bash
set -e

echo "=== ВОССТАНОВЛЕНИЕ WIREGUARD ИЗ ПРОЕКТА ==="

PROJECT_DIR="/opt/my-firewall-setup"

echo "📁 Копируем конфиг WireGuard..."
cp "$PROJECT_DIR/etc/wireguard/wg0.conf" /etc/wireguard/
chmod 600 /etc/wireguard/wg0.conf

echo "🔑 Копируем ключи..."
cp "$PROJECT_DIR/opt/zapret/server_private.key" /etc/wireguard/
cp "$PROJECT_DIR/opt/zapret/server_public.key" /etc/wireguard/
chmod 600 /etc/wireguard/server_private.key

echo "📋 Проверяем конфиг..."
cat /etc/wireguard/wg0.conf

echo ""
echo "🔧 Проверяем синтаксис конфига..."
wg-quick check wg0

echo ""
echo "🚀 Запускаем WireGuard..."
systemctl start wg-quick@wg0

echo ""
echo "⏳ Ждем 3 секунды..."
sleep 3

echo ""
echo "🔍 Проверяем статус..."
systemctl status wg-quick@wg0 --no-pager -l

echo ""
echo "🌐 Проверяем интерфейс..."
wg show
ip addr show wg0 2>/dev/null && echo "✅ WG0 запущен" || echo "❌ WG0 не запущен"

echo ""
echo "📊 Проверяем правила nftables..."
nft list ruleset | grep -A5 "queue to"

echo ""
echo "✅ Восстановление завершено!"
