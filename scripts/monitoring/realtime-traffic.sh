#!/bin/bash
echo "=== МОНИТОРИНГ ТРАФИКА В РЕАЛЬНОМ ВРЕМЕНИ ==="
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
    systemctl is-active wg-quick@wg0 &>/dev/null && echo -e "wg-quick@wg0: \033[0;32m✓\033[0m" || echo -e "wg-quick@wg0: \033[0;31m✗\033[0m"
    
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
    echo "=== КЛИЕНТЫ ==="
    wg show 2>/dev/null | grep "peer:" | while read line; do
        peer=$(echo $line | cut -d' ' -f2)
        handshake=$(wg show 2>/dev/null | grep -A5 "$peer" | grep "latest handshake" | cut -d: -f2 | xargs)
        if [ -n "$handshake" ]; then
            echo "🔗 $(echo $peer | head -c 20)...: подключен $handshake"
        else
            echo "⏳ $(echo $peer | head -c 20)...: ожидание"
        fi
    done
    
    echo ""
    echo "💡 Статус: $(systemctl is-active zapret-aggressive >/dev/null && echo 'СИСТЕМА РАБОТАЕТ' || echo 'ЕСТЬ ПРОБЛЕМЫ')"
    
    sleep 3
done
