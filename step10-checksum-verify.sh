#!/bin/bash
echo "=== ШАГ 10: ПРОВЕРКА КОНТРОЛЬНЫХ СУММ ==="

cd /opt/my-firewall-setup

# Функция для вычисления и сравнения MD5
check_md5() {
    local original=$1
    local backup=$2
    local description=$3
    
    if [ ! -f "$original" ] || [ ! -f "$backup" ]; then
        echo "⚠️  Пропускаем: $description (файлы отсутствуют)"
        return
    fi
    
    orig_md5=$(md5sum "$original" | cut -d' ' -f1)
    backup_md5=$(md5sum "$backup" | cut -d' ' -f1)
    
    if [ "$orig_md5" = "$backup_md5" ]; then
        echo "✅ $description: MD5 совпадает ($orig_md5)"
    else
        echo "❌ $description: MD5 не совпадает"
        echo "   Оригинал: $orig_md5"
        echo "   Копия:    $backup_md5"
    fi
}

echo "🔢 Проверяем контрольные суммы ключевых файлов..."

# Systemd службы
check_md5 "/etc/systemd/system/zapret-basic.service" "etc/systemd/system/zapret-basic.service" "zapret-basic.service"
check_md5 "/etc/systemd/system/zapret-aggressive.service" "etc/systemd/system/zapret-aggressive.service" "zapret-aggressive.service"

# Сетевые конфиги
check_md5 "/etc/wireguard/wg0.conf" "etc/wireguard/wg0.conf" "wg0.conf"
check_md5 "/etc/nftables.conf" "etc/nftables.conf" "nftables.conf"

# Бинарные файлы
if [ -f "/opt/zapret/nfq/nfqws" ]; then
    check_md5 "/opt/zapret/nfq/nfqws" "opt/zapret/nfq/nfqws" "nfqws (бинарный)"
fi

# Списки хостов
check_md5 "/opt/zapret/ipset/zapret-hosts-user.txt" "opt/zapret/ipset/zapret-hosts-user.txt" "zapret-hosts-user.txt"
check_md5 "/opt/zapret/ipset/youtube-hosts.txt" "opt/zapret/ipset/youtube-hosts.txt" "youtube-hosts.txt"

echo ""
echo "📈 Статистика файлов:"

echo "Оригинальная система (/opt/zapret):"
find /opt/zapret -type f | wc -l | xargs echo "  Файлов:"
du -sh /opt/zapret | cut -f1 | xargs echo "  Размер:"

echo "Резервная копия (/opt/my-firewall-setup):"
find /opt/my-firewall-setup -type f | wc -l | xargs echo "  Файлов:"
du -sh /opt/my-firewall-setup | cut -f1 | xargs echo "  Размер:"

echo ""
echo "✅ Проверка контрольных сумм завершена"
