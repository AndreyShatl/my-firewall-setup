#!/bin/bash
echo "=== МОНИТОРИНГ СИСТЕМЫ В РЕАЛЬНОМ ВРЕМЕНИ ==="
echo "Нажмите Ctrl+C для выхода"
echo ""

while true; do
    clear
    echo "🕐 $(date)"
    echo ""
    
    # Статус служб
    echo "=== СЛУЖБЫ ==="
    systemctl is-active zapret-basic &>/dev/null && echo -e "zapret-basic: \033[0;32m✓\033[0m" || echo -e "zapret-basic: \033[0;31m✗\033[0m"
    systemctl is-active zapret-aggressive &>/dev/null && echo -e "zapret-aggressive: \033[0;32m✓\033[0m" || echo -e "zapret-aggressive: \033[0;31m✗\033[0m"
    ip addr show wg0 &>/dev/null && echo -e "WireGuard: \033[0;32m✓\033[0m" || echo -e "WireGuard: \033[0;31m✗\033[0m"
    
    echo ""
    echo "=== ТРАФИК ==="
    nft list ruleset 2>/dev/null | grep "counter packets" | while read line; do
        packets=$(echo "$line" | grep -o 'packets [0-9]*' | cut -d' ' -f2)
        bytes=$(echo "$line" | grep -o 'bytes [0-9]*' | cut -d' ' -f2)
        queue=$(echo "$line" | grep -o 'queue to [0-9]*' | cut -d' ' -f3)
        if [ -n "$queue" ]; then
            echo "Очередь $queue: $packets пакетов"
        fi
    done
    
    echo ""
    echo "=== КЛИЕНТЫ WIREGUARD ==="
    wg show 2>/dev/null | grep "peer:" | while read line; do
        peer=$(echo $line | cut -d' ' -f2)
        handshake=$(wg show 2>/dev/null | grep -A5 "$peer" | grep "latest handshake" | cut -d: -f2 | xargs)
        if [ -n "$handshake" ]; then
            echo "🔗 $peer: подключен $handshake"
        else
            echo "⏳ $peer: ожидание"
        fi
    done
    
    sleep 5
done
