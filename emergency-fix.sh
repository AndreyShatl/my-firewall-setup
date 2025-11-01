#!/bin/bash
set -e

echo "=== АВАРИЙНОЕ ИСПРАВЛЕНИЕ СИСТЕМЫ ==="

echo "🔍 Анализируем проблемы..."
echo "1. Службы zapret не работают"
echo "2. Две очереди 200 в NFTables"
echo "3. Отсутствует конфиг WireGuard"

echo ""
echo "🛑 Останавливаем всё..."
systemctl stop zapret-basic zapret-aggressive 2>/dev/null || true
pkill nfqws 2>/dev/null || true

echo ""
echo "🔧 Исправляем NFTables правила..."
# Создаем чистый конфиг NFTables
cat > /etc/nftables.conf << 'NFT_EOF'
#!/usr/sbin/nft -f

flush ruleset

table inet nat {
    chain postrouting {
        type nat hook postrouting priority srcnat; policy accept;
        oifname "eno1" masquerade
    }
}

table inet zapret {
    set youtube_hosts {
        type ipv4_addr
        flags interval
        elements = {
            74.125.0.0/16,
            142.250.0.0/16,
            172.217.0.0/16,
            173.194.0.0/16,
            209.85.128.0/17,
            216.58.0.0/16,
            216.239.32.0/19
        }
    }

    chain prerouting {
        type filter hook prerouting priority mangle; policy accept;

        # YouTube трафик - очередь 201 (ПЕРВЫМ!)
        iifname "wg0" ip daddr @youtube_hosts tcp dport { 80, 443 } counter queue to 201

        # Остальной HTTP/HTTPS трафик - очередь 200
        iifname "wg0" tcp dport { 80, 443 } counter queue to 200

        # DNS трафик - очередь 200 (используем ту же очередь)
        iifname "wg0" udp dport 53 counter queue to 200
    }

    chain postrouting {
        type nat hook postrouting priority srcnat; policy accept;
        oifname "eno1" masquerade
    }
}
NFT_EOF

echo ""
echo "🔄 Применяем NFTables..."
nft -f /etc/nftables.conf

echo ""
echo "📋 Проверяем исправленные правила..."
nft list ruleset | grep -A10 "chain prerouting"

echo ""
echo "🔧 Восстанавливаем конфиг WireGuard..."
# Восстанавливаем из проекта
cp /opt/my-firewall-setup/etc/wireguard/wg0.conf /etc/wireguard/wg0.conf
chmod 600 /etc/wireguard/wg0.conf

echo ""
echo "🔄 Перезапускаем WireGuard..."
wg-quick down wg0 2>/dev/null || true
wg-quick up wg0

echo ""
echo "🚀 Запускаем Zapret службы..."
systemctl start zapret-basic
systemctl start zapret-aggressive

echo ""
echo "⏳ Ждем 5 секунд для стабилизации..."
sleep 5

echo ""
echo "🔍 Проверяем результаты..."
echo "Процессы nfqws:"
ps aux | grep nfqws | grep -v grep

echo ""
echo "NFTables правила:"
nft list ruleset | grep "queue to"

echo ""
echo "Статус служб:"
systemctl is-active zapret-basic && echo "✅ zapret-basic активен" || echo "❌ zapret-basic неактивен"
systemctl is-active zapret-aggressive && echo "✅ zapret-aggressive активен" || echo "❌ zapret-aggressive неактивен"
ip addr show wg0 &>/dev/null && echo "✅ WireGuard интерфейс работает" || echo "❌ WireGuard интерфейс не работает"

echo ""
echo "✅ Аварийное исправление завершено!"
