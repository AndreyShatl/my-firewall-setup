#!/bin/bash
echo "=== КОМПЛЕКСНАЯ ДИАГНОСТИКА СИСТЕМЫ ==="
echo "⏰ Время проверки: $(date)"
echo ""

# Цветовая палитра для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    if [ "$2" = "OK" ]; then
        echo -e "${GREEN}✅ $1${NC}"
    elif [ "$2" = "WARNING" ]; then
        echo -e "${YELLOW}⚠️  $1${NC}"
    else
        echo -e "${RED}❌ $1${NC}"
    fi
}

echo -e "${BLUE}=== 1. ПРОВЕРКА СЛУЖБ И ПРОЦЕССОВ ===${NC}"

# Проверка служб
services=("zapret-basic" "zapret-aggressive" "wg-quick@wg0")
for service in "${services[@]}"; do
    status=$(systemctl is-active "$service" 2>/dev/null)
    if [ "$status" = "active" ]; then
        print_status "$service: активна" "OK"
    elif [ "$status" = "failed" ]; then
        # Особый случай для WireGuard - проверяем работает ли он фактически
        if [ "$service" = "wg-quick@wg0" ] && ip addr show wg0 &>/dev/null; then
            print_status "$service: служба неактивна, но интерфейс работает" "WARNING"
        else
            print_status "$service: неактивна (failed)" "ERROR"
        fi
    else
        print_status "$service: неактивна" "ERROR"
    fi
done

echo ""
echo -e "${BLUE}=== 2. ПРОВЕРКА ПРОЦЕССОВ NFQWS ===${NC}"
nfqws_processes=$(ps aux | grep nfqws | grep -v grep)
if [ -n "$nfqws_processes" ]; then
    print_status "Процессы nfqws запущены:" "OK"
    echo "$nfqws_processes" | while read line; do
        echo "   📍 $line"
    done
else
    print_status "Процессы nfqws не найдены" "ERROR"
fi

echo ""
echo -e "${BLUE}=== 3. ДИАГНОСТИКА WIREGUARD ===${NC}"

# Проверка интерфейса
if ip addr show wg0 &>/dev/null; then
    print_status "Интерфейс wg0 существует" "OK"
    echo "   📊 Статистика интерфейса:"
    ip -s link show wg0 | grep -E "(RX|TX)" | head -2
else
    print_status "Интерфейс wg0 не существует" "ERROR"
fi

# Проверка WireGuard
wg_output=$(wg show 2>/dev/null)
if [ -n "$wg_output" ]; then
    print_status "WireGuard работает" "OK"
    peers=$(echo "$wg_output" | grep -c "peer:")
    connected_peers=$(echo "$wg_output" | grep "latest handshake" | wc -l)
    echo "   👥 Подключенные пиры: $connected_peers из $peers"
    
    # Детальная информация о пирах
    echo "$wg_output" | while read line; do
        if [[ $line == peer:* ]]; then
            peer_pubkey=$(echo $line | cut -d' ' -f2)
            echo "   🔑 Peer: ${peer_pubkey:0:20}..."
        elif [[ $line == *"latest handshake"* ]]; then
            echo "   🤝 $line"
        elif [[ $line == *"transfer:"* ]]; then
            echo "   📊 $line"
        fi
    done
else
    print_status "WireGuard не работает" "ERROR"
fi

echo ""
echo -e "${BLUE}=== 4. ПРОВЕРКА NFTABLES ===${NC}"

if nft list ruleset &>/dev/null; then
    print_status "NFTables работает" "OK"
    
    # Проверяем наличие таблицы zapret
    if nft list table inet zapret &>/dev/null; then
        print_status "Таблица zapret существует" "OK"
        
        # Проверяем цепочки
        chains=$(nft list table inet zapret | grep "chain" | wc -l)
        echo "   🔗 Количество цепочек: $chains"
        
        # Счетчики пакетов
        echo "   📈 Счетчики трафика:"
        nft list ruleset | grep "counter packets" | while read line; do
            packets=$(echo "$line" | grep -o 'packets [0-9]*' | cut -d' ' -f2)
            bytes=$(echo "$line" | grep -o 'bytes [0-9]*' | cut -d' ' -f2)
            queue=$(echo "$line" | grep -o 'queue to [0-9]*' | cut -d' ' -f3)
            if [ -n "$queue" ]; then
                echo "   🎯 Очередь $queue: $packets пакетов, $bytes байт"
            fi
        done
    else
        print_status "Таблица zapret не найдена" "ERROR"
    fi
else
    print_status "NFTables не работает" "ERROR"
fi

echo ""
echo -e "${BLUE}=== 5. ПРОВЕРКА ФАЙЛОВ КОНФИГУРАЦИИ ===${NC}"

# Проверяем основные конфиги
config_files=(
    "/etc/wireguard/wg0.conf"
    "/etc/nftables.conf"
    "/etc/systemd/system/zapret-basic.service"
    "/etc/systemd/system/zapret-aggressive.service"
    "/opt/my-firewall-setup/opt/zapret/ipset/youtube-hosts.txt"
    "/opt/my-firewall-setup/opt/zapret/ipset/zapret-hosts-user.txt"
)

for file in "${config_files[@]}"; do
    if [ -f "$file" ]; then
        size=$(stat -c%s "$file" 2>/dev/null || echo "0")
        if [ "$size" -gt 0 ]; then
            print_status "$file: существует ($size байт)" "OK"
        else
            print_status "$file: существует, но пустой" "WARNING"
        fi
    else
        print_status "$file: не существует" "ERROR"
    fi
done

echo ""
echo -e "${BLUE}=== 6. ПРОВЕРКА СЕТЕВЫХ НАСТРОЕК ===${NC}"

# Проверка IPv6
if sysctl net.ipv6.conf.all.disable_ipv6 | grep -q "1"; then
    print_status "IPv6 отключен глобально" "OK"
else
    print_status "IPv6 не отключен глобально" "WARNING"
fi

# Проверка IP forwarding
if sysctl net.ipv4.ip_forward | grep -q "1"; then
    print_status "IP forwarding включен" "OK"
else
    print_status "IP forwarding выключен" "ERROR"
fi

# Проверка порта WireGuard
if ss -tuln | grep -q ":51820"; then
    print_status "Порт 51820 слушается" "OK"
else
    print_status "Порт 51820 не слушается" "ERROR"
fi

echo ""
echo -e "${BLUE}=== 7. ПРОВЕРКА ДОСТУПНОСТИ ВНЕШНИХ РЕСУРСОВ ===${NC}"

test_hosts=("8.8.8.8" "google.com" "youtube.com" "googlevideo.com")
for host in "${test_hosts[@]}"; do
    if ping -c 1 -W 1 "$host" &>/dev/null; then
        print_status "$host: доступен" "OK"
    else
        print_status "$host: недоступен" "WARNING"
    fi
done

echo ""
echo -e "${BLUE}=== 8. ПРОВЕРКА СТРАТЕГИЙ ОБХОДА ===${NC}"

# Проверяем какие стратегии используются
if grep -q "split2" /etc/systemd/system/zapret-aggressive.service 2>/dev/null; then
    print_status "YouTube: используется стратегия split2" "OK"
else
    print_status "YouTube: стратегия не split2" "WARNING"
fi

if grep -q "fake" /etc/systemd/system/zapret-basic.service 2>/dev/null; then
    print_status "Базовый: используется стратегия fake" "OK"
else
    print_status "Базовый: стратегия не fake" "WARNING"
fi

# Проверяем hostlist для YouTube
if [ -f "/opt/my-firewall-setup/opt/zapret/ipset/youtube-hosts.txt" ]; then
    youtube_hosts_count=$(grep -v '^#' /opt/my-firewall-setup/opt/zapret/ipset/youtube-hosts.txt | grep -v '^$' | wc -l)
    echo "   📋 YouTube хостов в списке: $youtube_hosts_count"
    
    # Проверяем ключевые домены
    key_domains=("googlevideo.com" "youtubei.googleapis.com" "youtube.com")
    for domain in "${key_domains[@]}"; do
        if grep -q "$domain" /opt/my-firewall-setup/opt/zapret/ipset/youtube-hosts.txt; then
            print_status "Ключевой домен $domain присутствует" "OK"
        else
            print_status "Ключевой домен $domain отсутствует" "WARNING"
        fi
    done
fi

echo ""
echo -e "${BLUE}=== 9. ПРОВЕРКА ПРОИЗВОДИТЕЛЬНОСТИ ===${NC}"

# Проверяем загрузку CPU для процессов nfqws
echo "📊 Загрузка процессов:"
ps aux | grep nfqws | grep -v grep | awk '{print "   🖥️  " $11 " - CPU: " $3 "%, MEM: " $4 "%"}'

# Проверяем использование памяти
memory_usage=$(free -h | grep Mem | awk '{print $3 " / " $2}')
echo "   💾 Использование памяти: $memory_usage"

echo ""
echo -e "${BLUE}=== 10. РЕКОМЕНДАЦИИ ===${NC}"

# Анализируем и даем рекомендации
WARNINGS=()
ERRORS=()

# Проверяем предупреждения
if ! systemctl is-active wg-quick@wg0 &>/dev/null && ip addr show wg0 &>/dev/null; then
    WARNINGS+=("Служба WireGuard неактивна, но интерфейс работает. Рекомендуется исправить статус службы")
fi

if [ "$youtube_hosts_count" -lt 5 ]; then
    WARNINGS+=("Мало YouTube хостов в списке ($youtube_hosts_count). Рекомендуется расширить список")
fi

if ! sysctl net.ipv6.conf.all.disable_ipv6 | grep -q "1"; then
    WARNINGS+=("IPv6 не отключен глобально. Для лучшей работы YouTube рекомендуется отключить")
fi

# Выводим рекомендации
if [ ${#WARNINGS[@]} -gt 0 ]; then
    echo "⚠️  РЕКОМЕНДАЦИИ ДЛЯ УЛУЧШЕНИЯ:"
    for warning in "${WARNINGS[@]}"; do
        echo "   • $warning"
    done
else
    echo "✅ Критических проблем не обнаружено"
fi

echo ""
echo -e "${GREEN}=== ДИАГНОСТИКА ЗАВЕРШЕНА ===${NC}"
echo "📅 Время завершения: $(date)"
echo ""
echo "💡 Следующие шаги:"
echo "   1. Проверьте рекомендации выше"
echo "   2. Убедитесь, что клиенты подключаются к WireGuard"
echo "   3. Проверьте работу YouTube на клиентах"
echo "   4. Мониторьте счетчики трафика для отслеживания эффективности"
