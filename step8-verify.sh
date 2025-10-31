#!/bin/bash
echo "=== ШАГ 8: ПРОВЕРКА РЕЗЕРВНОЙ КОПИИ ==="

cd /opt/my-firewall-setup

echo "📁 Структура проекта:"
find . -type f | head -20

echo ""
echo "📊 Статистика:"
echo "Всего файлов: $(find . -type f | wc -l)"
echo "Общий размер: $(du -sh . | cut -f1)"

echo ""
echo "🔍 Проверка ключевых файлов:"
[ -f "etc/systemd/system/zapret-basic.service" ] && echo "✅ zapret-basic.service" || echo "❌ zapret-basic.service"
[ -f "etc/systemd/system/zapret-aggressive.service" ] && echo "✅ zapret-aggressive.service" || echo "❌ zapret-aggressive.service"
[ -f "etc/wireguard/wg0.conf" ] && echo "✅ wg0.conf" || echo "❌ wg0.conf"
[ -f "etc/nftables.conf" ] && echo "✅ nftables.conf" || echo "❌ nftables.conf"
[ -d "opt/zapret/nfq" ] && echo "✅ nfq/" || echo "❌ nfq/"
[ -d "opt/zapret/ipset" ] && echo "✅ ipset/" || echo "❌ ipset/"

echo "✅ Проверка завершена"
