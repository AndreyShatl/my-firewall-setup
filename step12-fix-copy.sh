#!/bin/bash
echo "=== ШАГ 12: ИСПРАВЛЕНИЕ ПРОБЛЕМ С КОПИРОВАНИЕМ ==="

cd /opt/my-firewall-setup

echo "🧹 Очищаем неправильно скопированные данные..."
# Удаляем вложенные папки, которые создались из-за ошибок копирования
rm -rf opt/zapret/nfq/nfq
rm -rf opt/zapret/ipset/ipset  
rm -rf opt/zapret/clients/clients

echo "📋 Проверяем что удалилось..."
find opt/zapret -type d -name "nfq" -o -name "ipset" -o -name "clients" | head -10

echo "🔄 Перекопируем проблемные директории правильно..."

echo "Копируем nfq заново..."
rm -rf opt/zapret/nfq/*
if [ -d "/opt/zapret/nfq" ]; then
    cp -r /opt/zapret/nfq/. opt/zapret/nfq/ 2>/dev/null
    echo "✅ nfq перекопирован"
    ls -la opt/zapret/nfq/ | head -10
else
    echo "❌ Оригинальная папка nfq не найдена"
fi

echo "Копируем ipset заново..."
rm -rf opt/zapret/ipset/*
if [ -d "/opt/zapret/ipset" ]; then
    cp -r /opt/zapret/ipset/. opt/zapret/ipset/ 2>/dev/null
    echo "✅ ipset перекопирован" 
else
    echo "❌ Оригинальная папка ipset не найдена"
fi

echo "Копируем clients заново..."
rm -rf opt/zapret/clients/*
if [ -d "/opt/zapret/clients" ]; then
    cp -r /opt/zapret/clients/. opt/zapret/clients/ 2>/dev/null
    echo "✅ clients перекопирован"
else
    echo "❌ Оригинальная папка clients не найдена"
fi

echo "🔍 Проверяем наличие критических файлов..."
[ -f "opt/zapret/nfq/nfqws" ] && echo "✅ nfqws найден" || echo "❌ nfqws ОТСУТСТВУЕТ"
[ -f "opt/zapret/ipset/zapret-hosts-user.txt" ] && echo "✅ zapret-hosts-user.txt найден" || echo "❌ zapret-hosts-user.txt ОТСУТСТВУЕТ"
[ -f "opt/zapret/ipset/youtube-hosts.txt" ] && echo "✅ youtube-hosts.txt найден" || echo "❌ youtube-hosts.txt ОТСУТСТВУЕТ"

echo "📊 Новая статистика:"
echo "Файлов в копии: $(find . -type f | wc -l)"
echo "Размер копии: $(du -sh . | cut -f1)"
