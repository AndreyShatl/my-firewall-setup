#!/bin/bash
echo "=== МОНИТОРИНГ ТРАФИКА В РЕАЛЬНОМ ВРЕМЕНИ ==="
echo "Нажмите Ctrl+C для выхода"
echo ""

# Сохраняем начальные значения счетчиков
get_counters() {
    nft list ruleset 2>/dev/null | grep "counter packets" | awk '{print $4, $6, $13}'
}

prev_counters=$(get_counters)

while true; do
    sleep 3
    current_counters=$(get_counters)
    
    clear
    echo "🕐 $(date)"
    echo "=== СТАТУС СЛУЖБ ==="
    systemctl is-active zapret-basic &>/dev/null && echo -e "zapret-basic: \033[0;32m✓\033[0m" || echo -e "zapret-basic: \033[0;31m✗\033[0m"
    systemctl is-active zapret-aggressive &>/dev/null && echo -e "zapret-aggressive: \033[0;32m✓\033[0m" || echo -e "zapret-aggressive: \033[0;31m✗\033[0m"
    ip addr show wg0 &>/dev/null && echo -e "WireGuard: \033[0;32m✓\033[0m" || echo -e "WireGuard: \033[0;31m✗\033[0m"
    
    echo ""
    echo "=== ТРАФИК (изменения за 3 сек) ==="
    
    # Сравниваем счетчики
    paste <(echo "$prev_counters") <(echo "$current_counters") | while IFS=$'\t' read -r prev current; do
        prev_packets=$(echo "$prev" | awk '{print $1}')
        prev_bytes=$(echo "$prev" | awk '{print $2}')
        queue=$(echo "$prev" | awk '{print $3}')
        
        current_packets=$(echo "$current" | awk '{print $1}')
        current_bytes=$(echo "$current" | awk '{print $2}')
        
        packet_diff=$((current_packets - prev_packets))
        byte_diff=$((current_bytes - prev_bytes))
        
        if [ "$packet_diff" -gt 0 ]; then
            echo -e "🎯 Очередь $queue: \033[0;32m+${packet_diff} пакетов, +${byte_diff} байт\033[0m"
        else
            echo -e "🎯 Очередь $queue: ${packet_diff} пакетов, ${byte_diff} байт"
        fi
    done
    
    echo ""
    echo "=== АКТИВНЫЕ ПРОЦЕССЫ ==="
    ps aux | grep nfqws | grep -v grep | while read process; do
        echo "   📍 $process"
    done
    
    prev_counters="$current_counters"
done
