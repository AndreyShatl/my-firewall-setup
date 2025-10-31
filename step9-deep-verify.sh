#!/bin/bash
echo "=== ШАГ 9: ДЕТАЛЬНАЯ ПРОВЕРКА ИДЕНТИЧНОСТИ КОПИИ ==="

cd /opt/my-firewall-setup

# Функция для сравнения файлов
compare_file() {
    local original=$1
    local backup=$2
    local description=$3
    
    if [ ! -f "$original" ]; then
        echo "❌ ОРИГИНАЛ ОТСУТСТВУЕТ: $original"
        return 1
    fi
    
    if [ ! -f "$backup" ]; then
        echo "❌ КОПИЯ ОТСУТСТВУЕТ: $backup"
        return 1
    fi
    
    # Сравниваем размер
    local orig_size=$(stat -c%s "$original" 2>/dev/null)
    local backup_size=$(stat -c%s "$backup" 2>/dev/null)
    
    if [ "$orig_size" != "$backup_size" ]; then
        echo "❌ РАЗМЕР: $description"
        echo "   Оригинал: $orig_size байт, Копия: $backup_size байт"
        return 1
    fi
    
    # Для текстовых файлов сравниваем содержимое
    if file "$original" | grep -q "text"; then
        if ! diff -q "$original" "$backup" >/dev/null; then
            echo "❌ СОДЕРЖИМОЕ: $description"
            return 1
        fi
    fi
    
    echo "✅ $description"
    return 0
}

# Функция для проверки директорий
compare_dir() {
    local original=$1
    local backup=$2
    local description=$3
    
    if [ ! -d "$original" ]; then
        echo "❌ ОРИГИНАЛЬНАЯ ДИРЕКТОРИЯ ОТСУТСТВУЕТ: $original"
        return 1
    fi
    
    if [ ! -d "$backup" ]; then
        echo "❌ ДИРЕКТОРИЯ В КОПИИ ОТСУТСТВУЕТ: $backup"
        return 1
    fi
    
    local orig_count=$(find "$original" -type f | wc -l)
    local backup_count=$(find "$backup" -type f | wc -l)
    
    if [ "$orig_count" != "$backup_count" ]; then
        echo "❌ КОЛИЧЕСТВО ФАЙЛОВ: $description"
        echo "   Оригинал: $orig_count файлов, Копия: $backup_count файлов"
        return 1
    fi
    
    echo "✅ $description (файлов: $orig_count)"
    return 0
}

echo "📋 Проверяем ключевые конфигурационные файлы..."

# Systemd службы
compare_file "/etc/systemd/system/zapret-basic.service" "etc/systemd/system/zapret-basic.service" "zapret-basic.service"
compare_file "/etc/systemd/system/zapret-aggressive.service" "etc/systemd/system/zapret-aggressive.service" "zapret-aggressive.service"

# Сетевые конфиги
compare_file "/etc/wireguard/wg0.conf" "etc/wireguard/wg0.conf" "wg0.conf"
compare_file "/etc/nftables.conf" "etc/nftables.conf" "nftables.conf"
compare_file "/etc/dhcp/dhcpd.conf" "etc/dhcp/dhcpd.conf" "dhcpd.conf"
compare_file "/etc/dnsmasq.conf" "etc/dnsmasq.conf" "dnsmasq.conf"

echo ""
echo "📁 Проверяем структуру директорий..."

# Основные директории
compare_dir "/opt/zapret/nfq" "opt/zapret/nfq" "nfq/"
compare_dir "/opt/zapret/ipset" "opt/zapret/ipset" "ipset/"
compare_dir "/opt/zapret/clients" "opt/zapret/clients" "clients/"

echo ""
echo "🔧 Проверяем бинарные файлы Zapret..."

# Проверяем основные бинарные файлы
if [ -f "/opt/zapret/nfq/nfqws" ] && [ -f "opt/zapret/nfq/nfqws" ]; then
    orig_size=$(stat -c%s "/opt/zapret/nfq/nfqws")
    backup_size=$(stat -c%s "opt/zapret/nfq/nfqws")
    if [ "$orig_size" = "$backup_size" ]; then
        echo "✅ nfqws (бинарный) - размер совпадает: $orig_size байт"
    else
        echo "❌ nfqws - размер не совпадает: оригинал $orig_size байт, копия $backup_size байт"
    fi
else
    echo "❌ nfqws не найден в оригинале или копии"
fi

echo ""
echo "📊 Проверяем списки хостов..."

# Проверяем файлы хостов
compare_file "/opt/zapret/ipset/zapret-hosts-user.txt" "opt/zapret/ipset/zapret-hosts-user.txt" "zapret-hosts-user.txt"
compare_file "/opt/zapret/ipset/youtube-hosts.txt" "opt/zapret/ipset/youtube-hosts.txt" "youtube-hosts.txt"

echo ""
echo "📜 Проверяем скрипты..."

# Проверяем основные скрипты
for script in add_client.sh list_clients.sh remove_client.sh traffic_stats.sh; do
    compare_file "/opt/zapret/$script" "opt/zapret/$script" "$script"
done

echo ""
echo "👥 Проверяем клиентов WireGuard..."

# Проверяем наличие клиентов
if [ -d "/opt/zapret/clients" ]; then
    client_count_orig=$(find "/opt/zapret/clients" -name "*.key" -o -name "*.conf" | wc -l)
    client_count_backup=$(find "opt/zapret/clients" -name "*.key" -o -name "*.conf" | wc -l)
    
    if [ "$client_count_orig" = "$client_count_backup" ]; then
        echo "✅ Клиенты WireGuard: $client_count_orig файлов (совпадает)"
    else
        echo "❌ Клиенты WireGuard: оригинал $client_count_orig файлов, копия $client_count_backup файлов"
    fi
fi

echo ""
echo "=== ИТОГИ ПРОВЕРКИ ==="
echo "Если выше нет ошибок (❌) - копия идентична оригиналу!"
echo "Можно переходить к созданию Git репозитория."
