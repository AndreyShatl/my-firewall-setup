#!/bin/bash
set -e

echo "=== ПОЛНОЕ ИСПРАВЛЕНИЕ СИСТЕМЫ ==="

echo "🔧 Создаем недостающие каталоги..."
mkdir -p /etc/wireguard
mkdir -p /opt/zapret/{nfq,ipset}

echo ""
echo "🔗 Создаем симлинки на бинарники..."
ln -sf /opt/my-firewall-setup/opt/zapret/nfq/nfqws /opt/zapret/nfq/nfqws
ln -sf /opt/my-firewall-setup/opt/zapret/ipset/youtube-hosts.txt /opt/zapret/ipset/
ln -sf /opt/my-firewall-setup/opt/zapret/ipset/zapret-hosts-user.txt /opt/zapret/ipset/

echo ""
echo "📋 Проверяем симлинки..."
ls -la /opt/zapret/nfq/nfqws
ls -la /opt/zapret/ipset/

echo ""
echo "🔄 Обновляем службы systemd для использования правильных путей..."

# Обновляем zapret-basic.service
cat > /etc/systemd/system/zapret-basic.service << 'ZAPRET_BASIC_EOF'
[Unit]
Description=Zapret Basic DPI Bypass
After=network.target

[Service]
Type=simple
ExecStart=/opt/my-firewall-setup/opt/zapret/nfq/nfqws --qnum=200 --dpi-desync=fake --filter-tcp=80,443 --hostlist=/opt/my-firewall-setup/opt/zapret/ipset/zapret-hosts-user.txt
Restart=always
User=root

[Install]
WantedBy=multi-user.target
ZAPRET_BASIC_EOF

# Обновляем zapret-aggressive.service
cat > /etc/systemd/system/zapret-aggressive.service << 'ZAPRET_AGGRESSIVE_EOF'
[Unit]
Description=Zapret Aggressive DPI Bypass for YouTube
After=network.target

[Service]
Type=simple
ExecStart=/opt/my-firewall-setup/opt/zapret/nfq/nfqws --qnum=201 --dpi-desync=split2 --filter-tcp=80,443 --hostlist=/opt/my-firewall-setup/opt/zapret/ipset/youtube-hosts.txt
Restart=always
RestartSec=5
User=root

[Install]
WantedBy=multi-user.target
ZAPRET_AGGRESSIVE_EOF

echo ""
echo "🔧 Восстанавливаем конфиг WireGuard..."
cp /opt/my-firewall-setup/etc/wireguard/wg0.conf /etc/wireguard/
chmod 600 /etc/wireguard/wg0.conf

echo ""
echo "🔄 Перезагружаем systemd и применяем настройки..."
systemctl daemon-reload

echo ""
echo "🚀 Запускаем все службы..."
systemctl start zapret-basic
systemctl start zapret-aggressive
systemctl start wg-quick@wg0

echo ""
echo "⏳ Ждем 5 секунд для стабилизации..."
sleep 5

echo ""
echo "🔍 Проверяем результаты..."
echo "=== Процессы nfqws ==="
ps aux | grep nfqws | grep -v grep

echo ""
echo "=== Статус служб ==="
systemctl is-active zapret-basic && echo "✅ zapret-basic активен" || echo "❌ zapret-basic неактивен"
systemctl is-active zapret-aggressive && echo "✅ zapret-aggressive активен" || echo "❌ zapret-aggressive неактивен"
systemctl is-active wg-quick@wg0 && echo "✅ wg-quick@wg0 активен" || echo "❌ wg-quick@wg0 неактивен"

echo ""
echo "=== NFTables правила ==="
nft list ruleset | grep "queue to"

echo ""
echo "=== WireGuard статус ==="
wg show

echo ""
echo "✅ Система исправлена!"
