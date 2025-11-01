#!/bin/bash
echo "=== УПРАВЛЕНИЕ СИСТЕМОЙ ОБХОДА БЛОКИРОВОК ==="

case "$1" in
    "status")
        echo "🔍 Статус системы:"
        echo "WireGuard интерфейс:" $(ip addr show wg0 2>/dev/null && echo "✅" || echo "❌")
        echo "Zapret процессы:" $(ps aux | grep nfqws | grep -v grep | wc -l)
        echo "Счетчики пакетов:"
        nft list ruleset | grep "counter packets" | while read line; do
            echo "  $line"
        done
        ;;
    "restart")
        echo "🔄 Перезапуск системы..."
        wg-quick down wg0 2>/dev/null
        sleep 2
        wg-quick up wg0
        systemctl restart zapret-basic zapret-aggressive
        echo "✅ Система перезапущена"
        ;;
    "clients")
        echo "📋 Подключенные клиенты:"
        wg show
        ;;
    "logs")
        echo "📝 Логи Zapret:"
        journalctl -u zapret-aggressive -n 10 --no-pager
        ;;
    "traffic")
        echo "📊 Статистика трафика:"
        nft list ruleset | grep "counter packets"
        ;;
    *)
        echo "Использование: $0 {status|restart|clients|logs|traffic}"
        echo "  status   - статус системы"
        echo "  restart  - перезапуск всех компонентов"
        echo "  clients  - список клиентов WireGuard"
        echo "  logs     - логи Zapret"
        echo "  traffic  - статистика трафика"
        ;;
esac
