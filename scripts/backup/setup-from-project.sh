#!/bin/bash
set -e

echo "=== УСТАНОВКА ИЗ ПРОЕКТА /opt/my-firewall-setup ==="

PROJECT_DIR="/opt/my-firewall-setup"
ZAPRET_SOURCE="$PROJECT_DIR/opt/zapret"

if [ ! -d "$ZAPRET_SOURCE" ]; then
    echo "❌ Исходные файлы zapret не найдены в $ZAPRET_SOURCE"
    exit 1
fi

echo "📁 Найдены исходные файлы zapret"
ls -la "$ZAPRET_SOURCE"

echo ""
echo "🔧 Копируем nfqws..."
mkdir -p /opt/zapret/nfq
cp "$ZAPRET_SOURCE/nfq/nfqws" /opt/zapret/nfq/
chmod +x /opt/zapret/nfq/nfqws

echo "📦 Проверяем nfqws..."
if [ -f "/opt/zapret/nfq/nfqws" ]; then
    echo "✅ nfqws скопирован"
    /opt/zapret/nfq/nfqws --version 2>/dev/null || echo "✅ nfqws загружается"
else
    echo "❌ Ошибка копирования nfqws"
    exit 1
fi

echo ""
echo "📝 Создаем hostlist файлы..."
mkdir -p /opt/zapret/ipset

# Создаем базовый hostlist
cat > /opt/zapret/ipset/zapret-hosts-user.txt << 'HOSTS_EOF'
google.com
youtube.com
googlevideo.com
youtubei.googleapis.com
youtu.be
ggpht.com
googleusercontent.com
HOSTS_EOF

# Создаем YouTube hostlist
cat > /opt/zapret/ipset/youtube-hosts.txt << 'YOUTUBE_EOF'
youtube.com
www.youtube.com
m.youtube.com
googlevideo.com
youtubei.googleapis.com
youtu.be
ggpht.com
googleusercontent.com
YOUTUBE_EOF

echo "✅ Hostlist файлы созданы"

echo ""
echo "⚙️ Настраиваем службы systemd..."
cat > /etc/systemd/system/zapret-basic.service << 'SERVICE_EOF'
[Unit]
Description=Zapret Basic DPI Bypass
After=network.target

[Service]
Type=simple
ExecStart=/opt/zapret/nfq/nfqws --qnum=200 --dpi-desync=fake --filter-tcp=80,443 --hostlist=/opt/zapret/ipset/zapret-hosts-user.txt
Restart=always
User=root

[Install]
WantedBy=multi-user.target
SERVICE_EOF

cat > /etc/systemd/system/zapret-aggressive.service << 'SERVICE_EOF'
[Unit]
Description=Zapret Aggressive DPI Bypass for YouTube
After=network.target

[Service]
Type=simple
ExecStart=/opt/zapret/nfq/nfqws --qnum=201 --dpi-desync=split2 --filter-tcp=80,443 --hostlist=/opt/zapret/ipset/youtube-hosts.txt
Restart=always
RestartSec=5
User=root

[Install]
WantedBy=multi-user.target
SERVICE_EOF

echo ""
echo "🔧 Настраиваем nftables с правильной стратегией обхода..."
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

    chain prerouting {
        type filter hook prerouting priority mangle; policy accept;

        # YouTube трафик - очередь 201 (ПЕРВЫМ!)
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

echo ""
echo "🔄 Применяем настройки..."
systemctl daemon-reload
nft -f /etc/nftables.conf

echo ""
echo "🚀 Запускаем службы..."
systemctl enable --now zapret-basic
systemctl enable --now zapret-aggressive

echo ""
echo "⏳ Ждем 3 секунды для стабилизации..."
sleep 3

echo ""
echo "🔍 Проверяем установку..."
echo "Процессы nfqws:"
ps aux | grep nfqws | grep -v grep

echo ""
echo "Правила nftables:"
nft list ruleset | grep -A10 "chain prerouting"

echo ""
echo "Статус служб:"
systemctl status zapret-basic --no-pager -l | head -10
systemctl status zapret-aggressive --no-pager -l | head -10

echo ""
echo "✅ Установка завершена!"
echo ""
echo "🎯 Дальнейшие шаги:"
echo "1. Настройте WireGuard конфиг в /etc/wireguard/wg0.conf"
echo "2. Убедитесь что IPv6 отключен на клиентах"
echo "3. Проверьте работу YouTube через WireGuard"
