#!/bin/bash
echo "=== АВТОМАТИЧЕСКОЕ ИСПРАВЛЕНИЕ ПРОБЛЕМ ==="

# Функция для проверки и исправления
fix_issue() {
    echo ""
    echo "🔧 Исправление: $1"
    eval "$2"
}

# 1. Исправление статуса службы WireGuard (если интерфейс работает, но служба нет)
if ip addr show wg0 &>/dev/null && ! systemctl is-active wg-quick@wg0 &>/dev/null; then
    fix_issue "Сброс статуса службы WireGuard" "systemctl reset-failed wg-quick@wg0 && systemctl start wg-quick@wg0"
fi

# 2. Проверка и включение IP forwarding
if ! sysctl net.ipv4.ip_forward | grep -q "1"; then
    fix_issue "Включение IP forwarding" "echo 'net.ipv4.ip_forward=1' >> /etc/sysctl.conf && sysctl -p"
fi

# 3. Проверка и отключение IPv6
if ! sysctl net.ipv6.conf.all.disable_ipv6 | grep -q "1"; then
    fix_issue "Отключение IPv6" "echo 'net.ipv6.conf.all.disable_ipv6=1' >> /etc/sysctl.conf && echo 'net.ipv6.conf.default.disable_ipv6=1' >> /etc/sysctl.conf && sysctl -p"
fi

# 4. Проверка и расширение YouTube hostlist
YOUTUBE_HOSTS_FILE="/opt/my-firewall-setup/opt/zapret/ipset/youtube-hosts.txt"
if [ -f "$YOUTUBE_HOSTS_FILE" ]; then
    count=$(grep -v '^#' "$YOUTUBE_HOSTS_FILE" | grep -v '^$' | wc -l)
    if [ "$count" -lt 10 ]; then
        fix_issue "Расширение списка YouTube хостов" "cat >> $YOUTUBE_HOSTS_FILE << 'EOL'
# Дополнительные YouTube хосты
www.googlevideo.com
m.googlevideo.com
---sn-.*.googlevideo.com
youtube-nocookie.com
www.youtube-nocookie.com
EOL"
    fi
fi

# 5. Проверка и перезапуск служб если нужно
fix_issue "Перезапуск служб для применения изменений" "systemctl restart zapret-basic zapret-aggressive"

echo ""
echo "✅ Автоматическое исправление завершено"
echo "🔄 Запустите диагностику снова чтобы проверить результаты: ./comprehensive-diagnostic.sh"
