#!/bin/bash
set -e

echo "=== ПОЛНОЕ ИСПРАВЛЕНИЕ НАСТРОЙКИ ==="

echo "🔧 Останавливаем все службы..."
systemctl stop zapret-basic 2>/dev/null || true
systemctl stop zapret-aggressive 2>/dev/null || true
pkill nfqws 2>/dev/null || true

echo "🔄 Обновляем правила nftables..."
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
            142.250.0.0/16,
            172.217.0.0/16,
            173.194.0.0/16,
            74.125.0.0/16,
            209.85.128.0/17,
            216.58.0.0/16,
            216.239.32.0/19
        }
    }

    set social_hosts {
        type ipv4_addr
        elements = { 149.154.167.91, 149.154.167.99 }
    }

    chain prerouting {
        type filter hook prerouting priority mangle; policy accept;

        # YouTube трафик - очередь 201 (В ПЕРВУЮ ОЧЕРЕДЬ!)
        iifname "wg0" ip daddr @youtube_hosts tcp dport { 80, 443 } counter queue to 201

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

echo "📋 Применяем новые правила..."
nft -f /etc/nftables.conf

echo "🚀 Запускаем службы..."
systemctl start zapret-basic
systemctl start zapret-aggressive

echo "⏳ Ждем 5 секунд для стабилизации..."
sleep 5

echo "🔍 Проверяем статус служб..."
echo "=== zapret-basic ==="
systemctl status zapret-basic --no-pager -l

echo ""
echo "=== zapret-aggressive ==="
systemctl status zapret-aggressive --no-pager -l

echo ""
echo "📊 Проверяем правила nftables..."
nft list ruleset | grep -A10 "chain prerouting"

echo ""
echo "🔍 Проверяем процессы nfqws..."
ps aux | grep nfqws | grep -v grep

echo ""
echo "🌐 Проверяем доступность YouTube..."
for ip in 142.250.74.110 142.250.74.174 172.217.22.174; do
    if ping -c 1 -W 1 $ip &>/dev/null; then
        echo "✅ $ip - доступен"
    else
        echo "⚠️  $ip - недоступен (может быть нормально)"
    fi
done

echo ""
echo "✅ Настройка завершена!"
echo "🎯 Теперь проверьте работу YouTube с клиента WireGuard"
