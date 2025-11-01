#!/bin/bash
set -e

echo "=== УСТАНОВКА ИЗ РЕЗЕРВНОЙ КОПИИ ПРОЕКТА ==="

PROJECT_DIR="/opt/my-firewall-setup"
BACKUP_DIR="$PROJECT_DIR/opt/zapret"

if [ ! -d "$BACKUP_DIR" ]; then
    echo "❌ Резервная копия не найдена в $BACKUP_DIR"
    echo "🔍 Ищем в других местах..."
    find /opt -name "nfqws" 2>/dev/null | head -5
    exit 1
fi

echo "📁 Найдена резервная копия: $BACKUP_DIR"
ls -la "$BACKUP_DIR"

echo ""
echo "🔧 Восстанавливаем структуру..."
mkdir -p /opt/zapret
cp -r "$BACKUP_DIR"/* /opt/zapret/
chmod +x /opt/zapret/nfq/nfqws 2>/dev/null || true

echo "📦 Проверяем nfqws..."
if [ -f "/opt/zapret/nfq/nfqws" ]; then
    echo "✅ nfqws восстановлен"
    /opt/zapret/nfq/nfqws --version 2>/dev/null || echo "⚠️  Не удалось проверить версию"
else
    echo "❌ nfqws не найден в резервной копии"
    exit 1
fi

echo ""
echo "📝 Восстанавливаем hostlist файлы..."
mkdir -p /opt/zapret/ipset

# Если есть резервные копии hostlist, используем их
if [ -f "$BACKUP_DIR/ipset/zapret-hosts-user.txt" ]; then
    cp "$BACKUP_DIR/ipset/zapret-hosts-user.txt" /opt/zapret/ipset/
    echo "✅ zapret-hosts-user.txt восстановлен"
else
    cat > /opt/zapret/ipset/zapret-hosts-user.txt << 'HOSTS_EOF'
google.com
youtube.com
googlevideo.com
youtubei.googleapis.com
youtu.be
ggpht.com
googleusercontent.com
HOSTS_EOF
    echo "✅ zapret-hosts-user.txt создан"
fi

if [ -f "$BACKUP_DIR/ipset/youtube-hosts.txt" ]; then
    cp "$BACKUP_DIR/ipset/youtube-hosts.txt" /opt/zapret/ipset/
    echo "✅ youtube-hosts.txt восстановлен"
else
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
    echo "✅ youtube-hosts.txt создан"
fi

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
echo "✅ Восстановление завершено!"
