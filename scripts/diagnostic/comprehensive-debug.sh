#!/bin/bash
echo "=== КОМПЛЕКСНАЯ ДИАГНОСТИКА ==="

echo "🔍 Проверяем сетевые интерфейсы..."
ip addr show wg0 2>/dev/null && echo "✅ WG0 существует" || echo "❌ WG0 не существует"

echo ""
echo "🌐 Проверяем маршрутизацию..."
ip route show table all | grep -E "(wg0|201|200)" || echo "Нет специальных маршрутов"

echo ""
echo "📊 Проверяем iptables правила..."
iptables -t mangle -L -n -v 2>/dev/null | grep -E "QUEUE|NFQUEUE" || echo "Нет iptables правил для очередей"

echo ""
echo "🔧 Проверяем nftables правила..."
nft list ruleset

echo ""
echo "🚀 Проверяем процессы nfqws..."
ps aux | grep nfqws | grep -v grep

echo ""
echo "📝 Проверяем конфиги служб..."
echo "=== zapret-basic ==="
systemctl cat zapret-basic 2>/dev/null | head -20
echo ""
echo "=== zapret-aggressive ==="
systemctl cat zapret-aggressive 2>/dev/null | head -20

echo ""
echo "🌐 Тестируем доступность YouTube..."
for ip in 142.250.74.110 142.250.74.174 172.217.22.174; do
    if ping -c 1 -W 1 $ip &>/dev/null; then
        echo "✅ $ip - доступен"
    else
        echo "❌ $ip - недоступен"
    fi
done

echo ""
echo "🎯 Рекомендации:"
echo "1. Если WG0 не существует, настройте WireGuard"
echo "2. Если процессы nfqws не запущены, проверьте конфиги служб"
echo "3. Если YouTube IP недоступны, проверьте базовую связность"
