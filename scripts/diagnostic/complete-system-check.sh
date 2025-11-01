#!/bin/bash
echo "=== ПОЛНАЯ ПРОВЕРКА СИСТЕМЫ ==="

echo "🔍 Процессы nfqws:"
ps aux | grep nfqws | grep -v grep

echo ""
echo "🌐 Сетевые интерфейсы:"
ip addr show wg0 && echo "✅ WG0 запущен" || echo "❌ WG0 не запущен"

echo ""
echo "📡 WireGuard:"
wg show && echo "✅ WireGuard работает" || echo "❌ WireGuard не работает"

echo ""
echo "⚙️ Службы:"
echo "zapret-basic: $(systemctl is-active zapret-basic)"
echo "zapret-aggressive: $(systemctl is-active zapret-aggressive)" 
echo "wg-quick@wg0: $(systemctl is-active wg-quick@wg0)"

echo ""
echo "📊 Правила nftables:"
nft list ruleset | grep -A5 "chain prerouting"

echo ""
echo "📈 Счетчики пакетов:"
nft list ruleset | grep "counter packets"

echo ""
echo "🌐 Проверка связности:"
ping -c 1 -W 1 8.8.8.8 >/dev/null 2>&1 && echo "✅ Внешний доступ есть" || echo "❌ Нет внешнего доступа"

echo ""
echo "🎯 СИСТЕМА ГОТОВА!"
echo ""
echo "📋 Клиенты в конфиге WireGuard:"
grep -A1 "PublicKey" /etc/wireguard/wg0.conf | grep -v "^\-\-$"

echo ""
echo "🎯 Дальнейшие шаги:"
echo "1. WireGuard запущен и слушает порт 51820"
echo "2. Создайте конфиги для клиентов с правильными приватными ключами"
echo "3. Настройте клиенты на подключение к вашему серверу"
echo "4. Проверьте работу YouTube через VPN"
echo ""
echo "📝 Для создания конфига клиента используйте:"
echo "   ./create-client-config.sh"
