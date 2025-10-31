#!/bin/bash
echo "=== ШАГ 20: ФИНАЛЬНАЯ ВЕРИФИКАЦИЯ ==="

cd /opt/my-firewall-setup

echo "🔍 Сравниваем структуру оригинала и копии:"
echo "Оригинал (/opt/zapret):"
ls -la /opt/zapret/ | head -10
echo ""
echo "Копия (opt/zapret):"  
ls -la opt/zapret/ | head -10

echo ""
echo "📊 Детальное сравнение:"
echo "Папка       | Оригинал | Копия  | Статус"
echo "------------|----------|--------|--------"
for dir in nfq ipset clients files tpws; do
    orig_count=$(find "/opt/zapret/$dir" -type f 2>/dev/null | wc -l)
    copy_count=$(find "opt/zapret/$dir" -type f 2>/dev/null | wc -l)
    if [ "$orig_count" -eq "$copy_count" ]; then
        status="✅"
    else
        status="❌"
    fi
    printf "%-11s | %-8s | %-6s | %s\n" "$dir" "$orig_count" "$copy_count" "$status"
done

echo ""
echo "🎯 Критически важные файлы:"
critical_files=(
    "/opt/zapret/nfq/nfqws:opt/zapret/nfq/nfqws"
    "/opt/zapret/ipset/zapret-hosts-user.txt:opt/zapret/ipset/zapret-hosts-user.txt"
    "/opt/zapret/ipset/youtube-hosts.txt:opt/zapret/ipset/youtube-hosts.txt"
    "/opt/zapret/add_client.sh:opt/zapret/add_client.sh"
)

for file_pair in "${critical_files[@]}"; do
    orig_file=$(echo "$file_pair" | cut -d: -f1)
    copy_file=$(echo "$file_pair" | cut -d: -f2)
    
    if [ -f "$orig_file" ] && [ -f "$copy_file" ]; then
        orig_size=$(stat -c%s "$orig_file" 2>/dev/null || echo "0")
        copy_size=$(stat -c%s "$copy_file" 2>/dev/null || echo "0")
        
        if [ "$orig_size" -eq "$copy_size" ]; then
            echo "✅ $(basename $orig_file): размер совпадает ($orig_size байт)"
        else
            echo "❌ $(basename $orig_file): размер не совпадает (ориг: $orig_size, копия: $copy_size)"
        fi
    else
        if [ ! -f "$orig_file" ]; then
            echo "❌ $(basename $orig_file): отсутствует в оригинале"
        fi
        if [ ! -f "$copy_file" ]; then
            echo "❌ $(basename $copy_file): отсутствует в копии"
        fi
    fi
done

echo ""
echo "📈 Итоговая статистика:"
echo "Оригинал: $(find /opt/zapret -type f | wc -l) файлов, $(du -sh /opt/zapret | cut -f1)"
echo "Копия:    $(find . -type f | wc -l) файлов, $(du -sh . | cut -f1)"

if [ $(find /opt/zapret -type f | wc -l) -eq $(find opt/zapret -type f | wc -l) ]; then
    echo ""
    echo "🎉 ПОЗДРАВЛЯЮ! Резервная копия создана успешно и идентична оригиналу!"
    echo "Теперь можно безопасно переходить к созданию Git репозитория."
else
    echo ""
    echo "⚠️  ВНИМАНИЕ: Есть расхождения между оригиналом и копией."
    echo "Рекомендуется устранить их перед созданием Git репозитория."
fi
