#!/bin/bash
echo "=== ДИАГНОСТИКА ВСЕЙ СИСТЕМЫ YOUTUBE ==="

echo "🔍 Проверяем процессы nfqws..."
ps aux | grep nfqws | grep -v grep

echo ""
echo "📊 Проверяем правила nftables для очередей..."
nft list ruleset | grep -E "queue to (200|201)"

echo ""
echo "🌐 Проверяем доступность YouTube хостов..."
for host in youtube.com googlevideo.com youtubei.googleapis.com; do
    if ping -c 1 -W 1 $host &> /dev/null; then
        echo "✅ $host - доступен"
    else
        echo "❌ $host - недоступен"
    fi
done

echo ""
echo "📝 Логи zapret-aggressive:"
journalctl -u zapret-aggressive -n 10 --no-pager

echo ""
echo "🎯 Рекомендации:"
echo "1. Убедитесь что WireGuard клиенты подключены"
echo "2. Проверьте что трафик идет через интерфейс wg0"
echo "3. Проверьте работу DNS на клиентах"
