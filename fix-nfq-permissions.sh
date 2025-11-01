#!/bin/bash
echo "=== ДИАГНОСТИКА И ИСПРАВЛЕНИЕ ОШИБКИ NFQUEUE ==="

echo "🔍 Проверяем текущие правила iptables для очереди 201..."
iptables -t mangle -L | grep -E "NFQUEUE.*201" || echo "❌ Правила для очереди 201 не найдены"

echo ""
echo "🔧 Проверяем права доступа..."
# Проверяем запускается ли служба от root
echo "Служба zapret-aggressive:"
systemctl cat zapret-aggressive | grep "User="

echo ""
echo "🚀 Попробуем запустить nfqws вручную с правами root..."
# Останавливаем службу
systemctl stop zapret-aggressive

# Запускаем вручную для диагностики
echo "Запускаем: /opt/zapret/nfq/nfqws --qnum=201 --dpi-desync=split2 --filter-tcp=80,443 --hostlist=/opt/zapret/ipset/youtube-hosts.txt"
timeout 5s /opt/zapret/nfq/nfqws --qnum=201 --dpi-desync=split2 --filter-tcp=80,443 --hostlist=/opt/zapret/ipset/youtube-hosts.txt

echo ""
echo "📋 Создаем исправленную службу..."
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

echo "🔄 Перезагружаем systemd..."
systemctl daemon-reload

echo "🚀 Запускаем службу..."
systemctl start zapret-aggressive

echo "⏳ Ждем 3 секунды..."
sleep 3

echo "🔍 Проверяем статус..."
systemctl status zapret-aggressive --no-pager -l

echo ""
echo "🎯 Если служба работает, проверьте YouTube"
echo "Если нет - нужно настроить правила iptables/nftables"
