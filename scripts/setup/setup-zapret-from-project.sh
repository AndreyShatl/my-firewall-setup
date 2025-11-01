#!/bin/bash
set -e

echo "=== УСТАНОВКА ZAPRET ИЗ ПРОЕКТА ==="

PROJECT_DIR="/opt/my-firewall-setup"

if [ ! -d "$PROJECT_DIR" ]; then
    echo "❌ Проект не найден в $PROJECT_DIR"
    exit 1
fi

echo "📁 Проект найден: $PROJECT_DIR"
ls -la "$PROJECT_DIR"

echo ""
echo "🔧 Создаем структуру каталогов..."
mkdir -p /opt/zapret/{nfq,ipset}
mkdir -p /etc/wireguard

echo "📦 Копируем файлы zapret..."
# Копируем nfqws
if [ -f "$PROJECT_DIR/nfqws" ]; then
    cp "$PROJECT_DIR/nfqws" /opt/zapret/nfq/
    chmod +x /opt/zapret/nfq/nfqws
    echo "✅ nfqws скопирован"
else
    echo "❌ nfqws не найден в проекте"
    exit 1
fi

echo ""
echo "📝 Создаем hostlist файлы..."
# Создаем базовые hostlist файлы
cat > /opt/zapret/ipset/zapret-hosts-user.txt << 'HOSTS_EOF'
# Базовые хосты для обхода DPI
google.com
youtube.com
googlevideo.com
youtubei.googleapis.com
youtu.be
ggpht.com
googleusercontent.com
HOSTS_EOF

cat > /opt/zapret/ipset/youtube-hosts.txt << 'YOUTUBE_EOF'
# YouTube хосты для агрессивного обхода
youtube.com
www.youtube.com
m.youtube.com
googlevideo.com
youtubei.googleapis.com
youtu.be
ggpht.com
googleusercontent.com
YOUTUBE_EOF

echo ""
echo "⚙️ Создаем службы systemd..."
# Служба для базового обхода
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

# Служба для агрессивного обхода YouTube
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
echo "🔧 Настраиваем nftables..."
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
echo "📊 Проверяем установку..."
echo "nfqws: $(/opt/zapret/nfq/nfqws --version 2>/dev/null || echo "установлен")"
echo "nftables: $(nft list ruleset | wc -l) правил"
echo "службы: $(systemctl list-unit-files | grep zapret | wc -l) служб"

echo ""
echo "✅ Установка завершена!"
echo ""
echo "🎯 Дальнейшие шаги:"
echo "1. Настройте WireGuard конфиг в /etc/wireguard/wg0.conf"
echo "2. Запустите: systemctl enable --now wg-quick@wg0"
echo "3. Запустите: systemctl enable --now zapret-basic zapret-aggressive"
echo "4. Проверьте: ./check-setup.sh"
