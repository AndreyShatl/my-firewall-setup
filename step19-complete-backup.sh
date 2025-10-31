#!/bin/bash
echo "=== ШАГ 19: СОЗДАНИЕ ПОЛНОЙ РЕЗЕРВНОЙ КОПИИ СИСТЕМЫ ==="

cd /opt/my-firewall-setup

echo "🧹 Очищаем старую копию Zapret..."
rm -rf opt/zapret/*

echo "📦 Копируем ВСЕ из /opt/zapret..."
if [ -d "/opt/zapret" ]; then
    cp -r /opt/zapret/. opt/zapret/ 2>&1 | head -10
    echo "✅ Копирование завершено"
else
    echo "❌ Оригинальная папка /opt/zapret не найдена"
    exit 1
fi

echo ""
echo "🔍 Проверяем ключевые компоненты:"

# Проверяем основные папки
for dir in nfq ipset clients files tpws; do
    if [ -d "opt/zapret/$dir" ]; then
        count=$(find "opt/zapret/$dir" -type f 2>/dev/null | wc -l)
        size=$(du -sh "opt/zapret/$dir" 2>/dev/null | cut -f1)
        echo "📁 $dir: $count файлов, $size"
    else
        echo "❌ $dir: отсутствует"
    fi
done

echo ""
echo "✅ Критические файлы:"
[ -f "opt/zapret/nfq/nfqws" ] && echo "  ✅ nfqws: СУЩЕСТВУЕТ" || echo "  ❌ nfqws: ОТСУТСТВУЕТ"
[ -f "opt/zapret/ipset/zapret-hosts-user.txt" ] && echo "  ✅ zapret-hosts-user.txt: СУЩЕСТВУЕТ" || echo "  ❌ zapret-hosts-user.txt: ОТСУТСТВУЕТ"
[ -f "opt/zapret/ipset/youtube-hosts.txt" ] && echo "  ✅ youtube-hosts.txt: СУЩЕСТВУЕТ" || echo "  ❌ youtube-hosts.txt: ОТСУТСТВУЕТ"

echo ""
echo "📊 Финальная статистика:"
echo "Оригинал: $(find /opt/zapret -type f | wc -l) файлов, $(du -sh /opt/zapret | cut -f1)"
echo "Копия:    $(find opt/zapret -type f | wc -l) файлов, $(du -sh opt/zapret | cut -f1)"

if [ $(find /opt/zapret -type f | wc -l) -eq $(find opt/zapret -type f | wc -l) ]; then
    echo ""
    echo "🎉 УРА! Теперь количество файлов совпадает!"
else
    echo ""
    echo "⚠️  Количество файлов все еще не совпадает."
    echo "Разница: $(($(find /opt/zapret -type f | wc -l) - $(find opt/zapret -type f | wc -l))) файлов"
fi
