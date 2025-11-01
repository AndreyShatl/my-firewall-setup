#!/bin/bash
echo "=== ГЛУБОКАЯ ДИАГНОСТИКА ZAPRET ==="

echo "🔍 Проверяем пути к бинарникам..."
ls -la /opt/my-firewall-setup/opt/zapret/nfq/nfqws

echo ""
echo "📋 Проверяем hostlist файлы..."
echo "YouTube hosts:"
ls -la /opt/my-firewall-setup/opt/zapret/ipset/youtube-hosts.txt
head -5 /opt/my-firewall-setup/opt/zapret/ipset/youtube-hosts.txt

echo ""
echo "Zapret hosts:"
ls -la /opt/my-firewall-setup/opt/zapret/ipset/zapret-hosts-user.txt
head -5 /opt/my-firewall-setup/opt/zapret/ipset/zapret-hosts-user.txt

echo ""
echo "🔧 Проверяем службы systemd..."
echo "=== zapret-basic ==="
systemctl cat zapret-basic
echo ""
echo "=== zapret-aggressive ==="
systemctl cat zapret-aggressive

echo ""
echo "📝 Логи служб:"
echo "--- zapret-basic ---"
journalctl -u zapret-basic -n 10 --no-pager
echo ""
echo "--- zapret-aggressive ---"
journalctl -u zapret-aggressive -n 10 --no-pager

echo ""
echo "🧪 Пробуем запустить вручную..."
echo "Запускаем zapret-basic:"
timeout 3s /opt/my-firewall-setup/opt/zapret/nfq/nfqws --qnum=200 --dpi-desync=fake --filter-tcp=80,443 --hostlist=/opt/my-firewall-setup/opt/zapret/ipset/zapret-hosts-user.txt &
BASIC_PID=$!
sleep 2
kill $BASIC_PID 2>/dev/null && echo "✅ zapret-basic запускается" || echo "❌ zapret-basic не запускается"

echo ""
echo "Запускаем zapret-aggressive:"
timeout 3s /opt/my-firewall-setup/opt/zapret/nfq/nfqws --qnum=201 --dpi-desync=split2 --filter-tcp=80,443 --hostlist=/opt/my-firewall-setup/opt/zapret/ipset/youtube-hosts.txt &
AGGRESSIVE_PID=$!
sleep 2
kill $AGGRESSIVE_PID 2>/dev/null && echo "✅ zapret-aggressive запускается" || echo "❌ zapret-aggressive не запускается"

echo ""
echo "🎯 Рекомендации:"
echo "Если ручной запуск работает, но службы нет - проблема в systemd"
echo "Если ручной запуск не работает - проблема в бинарнике или конфигах"
