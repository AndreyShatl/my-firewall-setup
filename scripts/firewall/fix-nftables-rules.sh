#!/bin/bash
set -e

echo "=== ИСПРАВЛЕНИЕ ПРАВИЛ NFTABLES ДЛЯ YOUTUBE ==="

echo "🔍 Анализируем текущие правила nftables..."
nft list ruleset

echo ""
echo "🛑 Останавливаем службы..."
systemctl stop zapret-basic
systemctl stop zapret-aggressive

echo "🔧 Исправляем правила для очереди 201..."

# Создаем новый конфиг nftables
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
        elements = { 
            142.250.74.110, 142.250.74.174, 172.217.22.174,
            142.250.74.78, 142.251.41.206, 172.217.18.174,
            142.250.185.78, 142.251.41.78, 172.217.22.142
        }
    }

    set social_hosts {
        type ipv4_addr
        elements = { 149.154.167.91, 149.154.167.99 }
    }

    chain prerouting {
        type filter hook prerouting priority mangle; policy accept;
        
        # YouTube трафик - очередь 201
        iifname "wg0" tcp dport { 80, 443 } ip daddr @youtube_hosts counter queue to 201
        
        # Остальной трафик - очередь 200
        iifname "wg0" tcp dport { 80, 443 } counter queue to 200
        
        # DNS трафик - очередь 200
        iifname "wg0" udp dport 53 counter queue to 200
    }

    chain postrouting {
        type nat hook postrouting priority srcnat; policy accept;
        oifname "eno1" masquerade
    }
}
NFT_EOF

echo "🔄 Применяем новые правила nftables..."
nft -f /etc/nftables.conf

echo "🚀 Запускаем службы..."
systemctl start zapret-basic
systemctl start zapret-aggressive

echo "⏳ Ждем 3 секунды..."
sleep 3

echo "🔍 Проверяем статус служб..."
systemctl status zapret-basic --no-pager -l
echo "---"
systemctl status zapret-aggressive --no-pager -l

echo ""
echo "📊 Проверяем правила nftables..."
nft list ruleset | grep -A 10 -B 5 "queue to 201"

echo ""
echo "🎯 Проверьте YouTube сейчас!"
echo "Если все еще не работает, запустите диагностику: ./debug-youtube-setup.sh"
