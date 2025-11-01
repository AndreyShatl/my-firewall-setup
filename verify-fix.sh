#!/bin/bash
echo "=== ПРОВЕРКА ИСПРАВЛЕНИЯ ==="

echo "🔍 Проверяем системные компоненты..."

echo ""
echo "1. Симлинки:"
ls -la /opt/zapret/nfq/nfqws
ls -la /opt/zapret/ipset/

echo ""
echo "2. Конфиг WireGuard:"
ls -la /etc/wireguard/wg0.conf

echo ""
echo "3. Службы systemd:"
systemctl status zapret-basic --no-pager -l | head -5
systemctl status zapret-aggressive --no-pager -l | head -5

echo ""
echo "4. Процессы:"
ps aux | grep nfqws | grep -v grep | while read process; do
    echo "   📍 $process"
done

echo ""
echo "5. Трафик через очереди:"
echo "Ожидаем 10 секунд для накопления трафика..."
sleep 10

echo "Счетчики пакетов:"
nft list ruleset | grep "counter packets" | while read line; do
    packets=$(echo "$line" | grep -o 'packets [0-9]*' | cut -d' ' -f2)
    bytes=$(echo "$line" | grep -o 'bytes [0-9]*' | cut -d' ' -f2)
    queue=$(echo "$line" | grep -o 'queue to [0-9]*' | cut -d' ' -f3)
    if [ -n "$queue" ]; then
        echo "   🎯 Очередь $queue: $packets пакетов"
    fi
done

echo ""
echo "6. Клиенты WireGuard:"
wg show | grep -E "(peer:|latest handshake:|transfer:)" | while read line; do
    if [[ $line == peer:* ]]; then
        echo "   🔑 $(echo $line | cut -d' ' -f2 | head -c 20)..."
    else
        echo "   📊 $line"
    fi
done

echo ""
echo "🎯 РЕКОМЕНДАЦИЯ:"
echo "Если счетчики очередей увеличиваются - система работает!"
echo "Проверьте YouTube на подключенных клиентах."
