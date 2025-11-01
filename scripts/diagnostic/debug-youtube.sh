#!/bin/bash
echo "=== ДИАГНОСТИКА YOUTUBE ==="

echo "🔍 Проверяем списки хостов YouTube..."
echo "Файл: /opt/zapret/ipset/youtube-hosts.txt"
echo "Количество хостов: $(wc -l < /opt/zapret/ipset/youtube-hosts.txt)"
echo "Первые 5 хостов:"
head -5 /opt/zapret/ipset/youtube-hosts.txt

echo ""
echo "🌐 Проверяем DNS разрешение YouTube..."
for host in $(head -3 /opt/zapret/ipset/youtube-hosts.txt); do
    ip=$(dig +short $host | head -1)
    echo "DNS $host: $ip"
done

echo ""
echo "📊 Проверяем процессы nfqws..."
ps aux | grep nfqws | grep -v grep

echo ""
echo "🔧 Проверяем правила iptables/nftables..."
echo "NFTables правила:"
nft list ruleset 2>/dev/null | grep -E "queue|201" || echo "NFTables правила для очереди 201 не найдены"

echo ""
echo "📝 Логи zapret-aggressive (последние 10 строк):"
journalctl -u zapret-aggressive -n 10 --no-pager

echo ""
echo "🎯 Текущая стратегия:"
systemctl cat zapret-aggressive | grep ExecStart

echo ""
echo "💡 Рекомендации:"
echo "1. Проверьте что в файле /opt/zapret/ipset/youtube-hosts.txt есть актуальные хосты YouTube"
echo "2. Убедитесь что служба zapret-aggressive активна: systemctl status zapret-aggressive"
echo "3. Если хостов мало, обновите списки: /opt/zapret/update-all-hosts.sh"
