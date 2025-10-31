#!/bin/bash
echo "=== ШАГ 17: ПОИСК БИНАРНОГО ФАЙЛА NFQWS ==="

echo "🔍 Ищем nfqws в оригинальной системе..."
find /opt/zapret -name "nfqws" -type f 2>/dev/null

echo ""
echo "📁 Проверяем, что есть в папке nfq оригинала:"
ls -la /opt/zapret/nfq/ | grep -E "nfqws|total"

echo ""
echo "🔧 Проверяем, где может быть собранный бинарный файл:"
# Проверяем стандартные места для бинарных файлов
for dir in /usr/local/bin /usr/bin /opt/zapret /opt/zapret/nfq /opt/zapret/tpws; do
    if [ -f "$dir/nfqws" ]; then
        echo "✅ НАЙДЕН: $dir/nfqws"
        ls -la "$dir/nfqws"
    fi
done

echo ""
echo "📋 Проверяем процессы systemd, чтобы понять какой бинарный файл используется:"
systemctl status zapret-basic 2>/dev/null | grep -o "/[^ ]*nfqws[^ ]*" | head -1
systemctl status zapret-aggressive 2>/dev/null | grep -o "/[^ ]*nfqws[^ ]*" | head -1

echo ""
echo "🔎 Проверяем, может быть nfqws это скрипт, а не бинарный файл:"
if [ -f "/opt/zapret/nfq/nfqws" ]; then
    file "/opt/zapret/nfq/nfqws"
else
    echo "❌ nfqws не найден как файл в /opt/zapret/nfq/"
fi
