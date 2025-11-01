#!/bin/bash
set -e

echo "=== ФИНАЛЬНОЕ ИСПРАВЛЕНИЕ WIREGUARD ==="

echo "🔍 Проверяем реальный статус WireGuard..."
wg show
ip addr show wg0

echo ""
echo "🔄 Сбрасываем статус systemd..."
systemctl reset-failed wg-quick@wg0

echo ""
echo "🚀 Перезапускаем службу..."
systemctl restart wg-quick@wg0

echo ""
echo "⏳ Ждем 3 секунды..."
sleep 3

echo ""
echo "🔍 Проверяем статус..."
systemctl status wg-quick@wg0 --no-pager -l

echo ""
echo "🌐 Проверяем интерфейс..."
ip addr show wg0 && echo "✅ WG0 запущен" || echo "❌ WG0 не запущен"

echo ""
echo "📡 Проверяем подключения..."
wg show

echo ""
echo "✅ WireGuard исправлен!"
