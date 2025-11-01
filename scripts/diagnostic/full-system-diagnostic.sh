#!/bin/bash
echo "=== ПОЛНАЯ ДИАГНОСТИКА СИСТЕМЫ ==="

echo ""
echo "🔍 1. ПРОВЕРКА СЛУЖБ"
services=("zapret-basic" "zapret-aggressive" "wg-quick@wg0")
for service in "${services[@]}"; do
    status=$(systemctl is-active "$service")
    if [ "$status" = "active" ]; then
        echo "✅ $service: активна"
    else
        echo "❌ $service: неактивна или не запущена"
    fi
done

echo ""
echo "🔍 2. ПРОЦЕССЫ nfqws"
ps aux | grep nfqws | grep -v grep
if [ $? -eq 0 ]; then
    echo "✅ Процессы nfqws запущены"
else
    echo "❌ Процессы nfqws не найдены"
fi

echo ""
echo "🔍 3. WIREGUARD"
wg show
if [ $? -eq 0 ]; then
    echo "✅ WireGuard работает"
else
    echo "❌ WireGuard не работает"
fi

echo ""
echo "🔍 4. ИНТЕРФЕЙС WIREGUARD"
ip addr show wg0
if [ $? -eq 0 ]; then
    echo "✅ Интерфейс wg0 существует"
else
    echo "❌ Интерфейс wg0 не существует"
fi

echo ""
echo "🔍 5. ПРАВИЛА NFTABLES"
nft list ruleset > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "✅ Правила nftables загружены"
    # Показать счетчики пакетов
    echo "Счетчики пакетов:"
    nft list ruleset | grep "counter packets"
else
    echo "❌ Ошибка в правилах nftables"
fi

echo ""
echo "🔍 6. ПРОВЕРКА HOSTLIST ФАЙЛОВ"
youtube_hosts="/opt/my-firewall-setup/opt/zapret/ipset/youtube-hosts.txt"
zapret_hosts="/opt/my-firewall-setup/opt/zapret/ipset/zapret-hosts-user.txt"

if [ -f "$youtube_hosts" ]; then
    echo "✅ YouTube hostlist существует: $youtube_hosts"
    echo "   Количество записей: $(grep -v '^#' "$youtube_hosts" | grep -v '^$' | wc -l)"
else
    echo "❌ YouTube hostlist не существует: $youtube_hosts"
fi

if [ -f "$zapret_hosts" ]; then
    echo "✅ Zapret hostlist существует: $zapret_hosts"
    echo "   Количество записей: $(grep -v '^#' "$zapret_hosts" | grep -v '^$' | wc -l)"
else
    echo "❌ Zapret hostlist не существует: $zapret_hosts"
fi

echo ""
echo "🔍 7. ПРОВЕРКА СТРАТЕГИЙ ОБХОДА"
aggressive_service="/etc/systemd/system/zapret-aggressive.service"
if grep -q "split2" "$aggressive_service"; then
    echo "✅ Zapret-aggressive использует стратегию split2"
else
    echo "❌ Zapret-aggressive не использует стратегию split2"
fi

basic_service="/etc/systemd/system/zapret-basic.service"
if grep -q "fake" "$basic_service"; then
    echo "✅ Zapret-basic использует стратегию fake"
else
    echo "❌ Zapret-basic не использует стратегию fake"
fi

echo ""
echo "🔍 8. ПРОВЕРКА НАЛИЧИЯ BINARY NFQWS"
if [ -f "/opt/my-firewall-setup/opt/zapret/nfq/nfqws" ]; then
    echo "✅ nfqws найден в проекте"
else
    echo "❌ nfqws не найден в проекте"
fi

echo ""
echo "🔍 9. ПРОВЕРКА КОНФИГОВ WIREGUARD"
wg_conf="/etc/wireguard/wg0.conf"
if [ -f "$wg_conf" ]; then
    echo "✅ Конфиг WireGuard существует: $wg_conf"
    # Проверим, есть ли пиры
    peers=$(grep -c "PublicKey" "$wg_conf")
    echo "   Количество пиров: $peers"
else
    echo "❌ Конфиг WireGuard не существует: $wg_conf"
fi

echo ""
echo "🔍 10. ПРОВЕРКА ДОСТУПНОСТИ YOUTUBE"
# Проверим доступность ключевых доменов YouTube
domains=("googlevideo.com" "youtubei.googleapis.com" "youtube.com")
for domain in "${domains[@]}"; do
    if ping -c 1 -W 1 "$domain" &> /dev/null; then
        echo "✅ $domain доступен"
    else
        echo "❌ $domain недоступен"
    fi
done

echo ""
echo "🔍 11. ПРОВЕРКА DNS"
# Проверим, что DNS разрешает домены YouTube
for domain in "${domains[@]}"; do
    if dig +short "$domain" | head -1; then
        echo "✅ DNS разрешает $domain"
    else
        echo "❌ DNS не разрешает $domain"
    fi
done

echo ""
echo "🔍 12. ПРОВЕРКА IPv6"
if sysctl net.ipv6.conf.all.disable_ipv6 | grep -q "1"; then
    echo "✅ IPv6 отключен глобально"
else
    echo "❌ IPv6 не отключен глобально"
fi

echo ""
echo "🔍 13. ПРОВЕРКА ПЕРЕНАПРАВЛЕНИЯ ПАКЕТОВ"
if sysctl net.ipv4.ip_forward | grep -q "1"; then
    echo "✅ IP forwarding включен"
else
    echo "❌ IP forwarding не включен"
fi

echo ""
echo "🎯 ДИАГНОСТИКА ЗАВЕРШЕНА"
echo "Если вы видите много '✅', то система настроена хорошо."
echo "Если есть '❌', обратите внимание на эти пункты."
