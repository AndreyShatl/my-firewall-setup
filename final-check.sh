#!/bin/bash
echo "=== ФИНАЛЬНАЯ ПРОВЕРКА СИСТЕМЫ ==="

echo "🔍 Процессы nfqws:"
ps aux | grep nfqws | grep -v grep

echo ""
echo "🌐 Интерфейс WireGuard:"
ip addr show wg0 2>/dev/null && echo "✅ WG0 существует" || echo "❌ WG0 не существует"
wg show 2>/dev/null && echo "✅ WireGuard работает" || echo "❌ WireGuard не работает"

echo ""
echo "📊 Правила nftables:"
nft list ruleset | grep -A10 "chain prerouting"

echo ""
echo "⚙️ Службы:"
systemctl is-active zapret-basic && echo "✅ zapret-basic активен" || echo "❌ zapret-basic не активен"
systemctl is-active zapret-aggressive && echo "✅ zapret-aggressive активен" || echo "❌ zapret-aggressive не активен"
systemctl is-active wg-quick@wg0 && echo "✅ wg-quick@wg0 активен" || echo "❌ wg-quick@wg0 не активен"

echo ""
echo "📈 Счетчики пакетов:"
nft list ruleset | grep "counter packets"

echo ""
echo "🌐 Проверка доступности YouTube IP:"
for ip in 142.250.74.110 142.250.74.174 172.217.22.174; do
    if ping -c 1 -W 1 $ip &>/dev/null; then
        echo "✅ $ip - доступен"
    else
        echo "⚠️  $ip - недоступен (может быть нормально)"
    fi
done

echo ""
echo "✅ Проверка завершена!"
echo ""
echo "🎯 Если все службы активны и WireGuard запущен:"
echo "1. Скачайте конфиг клиента: /etc/wireguard/test-client.conf"
echo "2. Импортируйте его в WireGuard клиент на устройстве"
echo "3. Подключитесь и проверьте YouTube"
