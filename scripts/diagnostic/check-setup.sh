#!/bin/bash
echo "=== ПРОВЕРКА НАСТРОЙКИ ==="

echo "🔍 Процессы nfqws:"
ps aux | grep nfqws | grep -v grep

echo ""
echo "📊 Правила nftables:"
nft list ruleset

echo ""
echo "🌐 Интерфейс wg0:"
ip addr show wg0 2>/dev/null && echo "✅ WG0 существует" || echo "❌ WG0 не существует"

echo ""
echo "⚙️ Службы:"
systemctl status zapret-basic --no-pager -l
echo "---"
systemctl status zapret-aggressive --no-pager -l

echo ""
echo "📈 Счетчики пакетов:"
nft list ruleset | grep "counter packets" | head -10
