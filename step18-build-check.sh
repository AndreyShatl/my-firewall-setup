#!/bin/bash
echo "=== ШАГ 18: ПРОВЕРКА СБОРКИ ZAPRET ==="

echo "🔍 Проверяем, есть ли Makefile в исходниках..."
if [ -f "/opt/zapret/nfq/Makefile" ] || [ -f "/opt/zapret/nfq/makefile" ]; then
    echo "✅ Makefile найден"
    # Показываем первую часть Makefile
    head -20 /opt/zapret/nfq/Makefile 2>/dev/null | head -10
else
    echo "❌ Makefile не найден"
fi

echo ""
echo "📋 Проверяем есть ли собранные бинарные файлы в системе:"
find /opt/zapret -type f -executable -name "nfqws" -o -name "tpws" 2>/dev/null

echo ""
echo "🔧 Проверяем процессы, использующие nfqws:"
ps aux | grep nfqws | grep -v grep

echo ""
echo "📁 Содержимое /opt/zapret (кратко):"
ls -la /opt/zapret/ | head -15
