#!/bin/bash
set -e

echo "=== ИСПРАВЛЕНИЕ РАБОТЫ YOUTUBE ==="

echo "🛑 Останавливаем проблемную службу..."
systemctl stop zapret-aggressive

echo "🔧 Создаем исправленную службу с полной стратегией..."

# Создаем службу с правильной строкой ExecStart
cat > /etc/systemd/system/zapret-aggressive.service << SERVICE_EOF
[Unit]
Description=Zapret Aggressive DPI Bypass for YouTube
After=network.target

[Service]
Type=simple
ExecStart=/opt/zapret/nfq/nfqws --qnum=201 --dpi-desync=fake,multisplit --dpi-desync-split-seqovl=681 --dpi-desync-split-pos=1 --dpi-desync-fooling=badseq --dpi-desync-badseq-increment=10000000 --dpi-desync-repeats=2 --dpi-desync-fake-tls-mod=rnd,dupsid,sni=fonts.google.com --filter-tcp=80,443 --hostlist=/opt/zapret/ipset/youtube-hosts.txt
Restart=always
RestartSec=5
User=root

[Install]
WantedBy=multi-user.target
SERVICE_EOF

echo "🔄 Перезагружаем демон systemd..."
systemctl daemon-reload

echo "🚀 Запускаем исправленную службу..."
systemctl start zapret-aggressive

echo "⏳ Ждем 3 секунды для стабилизации..."
sleep 3

echo "🔍 Проверяем статус службы..."
systemctl status zapret-aggressive --no-pager -l

echo "✅ Основное исправление завершено!"
echo ""
echo "🎯 Если YouTube все еще не работает, запустите:"
echo "   ./test-youtube-strategies.sh"
