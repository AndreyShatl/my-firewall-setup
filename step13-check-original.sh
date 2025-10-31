#!/bin/bash
echo "=== ШАГ 13: АНАЛИЗ ОРИГИНАЛЬНОЙ СТРУКТУРЫ ==="

echo "📁 Структура оригинального /opt/zapret:"
echo "Общие файлы: $(find /opt/zapret -type f | wc -l)"
echo "Общий размер: $(du -sh /opt/zapret | cut -f1)"

echo ""
echo "🔍 Критические файлы в оригинале:"
find /opt/zapret/nfq -name "nfqws" -type f | head -5
find /opt/zapret/nfq -type f -name "*.c" -o -name "*.h" | head -5

echo ""
echo "📊 Директории оригинала:"
for dir in nfq ipset clients; do
    if [ -d "/opt/zapret/$dir" ]; then
        count=$(find "/opt/zapret/$dir" -type f | wc -l)
        size=$(du -sh "/opt/zapret/$dir" | cut -f1)
        echo "  /opt/zapret/$dir: $count файлов, $size"
    else
        echo "  ❌ /opt/zapret/$dir: ОТСУТСТВУЕТ"
    fi
done

echo ""
echo "🔧 Бинарные файлы:"
find /opt/zapret -type f -executable -name "nfqws" -o -name "*.so" -o -name "*.bin" | head -10

echo ""
echo "📝 Конфиги и скрипты:"
find /opt/zapret -name "*.sh" -o -name "*.conf" -o -name "*.txt" | head -10
