#!/bin/bash
set -e

echo "=== ДИАГНОСТИКА И ИСПРАВЛЕНИЕ ZAPRET-AGGRESSIVE ==="

echo "🔍 Проверяем процессы nfqws..."
ps aux | grep nfqws | grep -v grep

echo ""
echo "📊 Проверяем использование очередей..."
nft list ruleset | grep -A5 -B5 "queue to"

echo ""
echo "🔧 Останавливаем все службы zapret..."
systemctl stop zapret-basic 2>/dev/null || true
systemctl stop zapret-aggressive 2>/dev/null || true

echo "🔄 Убиваем все процессы nfqws..."
pkill nfqws || true
sleep 2

echo "📝 Проверяем файл youtube-hosts..."
if [ -f "/opt/zapret/ipset/youtube-hosts.txt" ]; then
    echo "✅ Файл существует, количество хостов: $(wc -l < /opt/zapret/ipset/youtube-hosts.txt)"
    head -5 /opt/zapret/ipset/youtube-hosts.txt
else
    echo "❌ Файл youtube-hosts.txt не существует!"
    echo "Создаем базовый список YouTube хостов..."
    mkdir -p /opt/zapret/ipset/
    cat > /opt/zapret/ipset/youtube-hosts.txt << 'HOSTS_EOF'
youtube.com
googlevideo.com
youtubei.googleapis.com
youtu.be
ggpht.com
googleusercontent.com
HOSTS_EOF
fi

echo ""
echo "🚀 Пробуем запустить zapret-aggressive вручную..."
echo "Команда: /opt/zapret/nfq/nfqws --qnum=201 --dpi-desync=split2 --filter-tcp=80,443 --hostlist=/opt/zapret/ipset/youtube-hosts.txt"
/opt/zapret/nfq/nfqws --qnum=201 --dpi-desync=split2 --filter-tcp=80,443 --hostlist=/opt/zapret/ipset/youtube-hosts.txt &

echo ""
echo "⏳ Ждем 3 секунды..."
sleep 3

echo ""
echo "🔍 Проверяем процессы после ручного запуска..."
ps aux | grep nfqws | grep -v grep

echo ""
echo "🛑 Останавливаем ручной процесс..."
pkill nfqws || true

echo ""
echo "🚀 Запускаем службы через systemctl..."
systemctl start zapret-aggressive
sleep 2

echo ""
echo "📋 Статус служб:"
systemctl status zapret-aggressive --no-pager -l

echo ""
echo "🎯 Проверяем логи за последние 10 секунд..."
journalctl -u zapret-aggressive --since "10 seconds ago" --no-pager

echo ""
echo "✅ Диагностика завершена"
