#!/bin/bash
echo "=== ШАГ 16: ПОЛНОЕ КОПИРОВАНИЕ ВСЕЙ СТРУКТУРЫ ZAPRET ==="

cd /opt/my-firewall-setup

echo "📊 Анализируем полную структуру оригинала..."
echo "Все папки в /opt/zapret:"
ls -la /opt/zapret/

echo ""
echo "🔄 Начинаем полное копирование всей структуры Zapret..."

# Создаем полную структуру папок в копии
mkdir -p opt/zapret/{nfq,ipset,clients,files,tpws,logs,doc}

echo "Копируем ВСЕ содержимое /opt/zapret..."
if [ -d "/opt/zapret" ]; then
    # Копируем все файлы и папки из /opt/zapret
    cp -r /opt/zapret/* opt/zapret/ 2>/dev/null
    
    # Проверяем, что скопировались основные папки
    for dir in nfq ipset clients files tpws; do
        if [ -d "opt/zapret/$dir" ]; then
            count=$(find "opt/zapret/$dir" -type f 2>/dev/null | wc -l)
            echo "✅ $dir: $count файлов"
        else
            echo "❌ $dir: не скопирована"
        fi
    done
else
    echo "❌ Оригинальная папка /opt/zapret не найдена"
fi

echo ""
echo "🔍 Проверяем критические файлы:"

critical_files=(
    "opt/zapret/nfq/nfqws"
    "opt/zapret/ipset/zapret-hosts-user.txt"
    "opt/zapret/ipset/youtube-hosts.txt"
    "opt/zapret/clients/test_client/wg0.conf"
    "opt/zapret/add_client.sh"
    "opt/zapret/list_clients.sh"
)

for file in "${critical_files[@]}"; do
    if [ -f "$file" ]; then
        size=$(stat -c%s "$file" 2>/dev/null || echo "0")
        echo "✅ $(basename $file): найден ($size байт)"
    else
        echo "❌ $(basename $file): ОТСУТСТВУЕТ"
    fi
done

echo ""
echo "📊 Статистика после полного копирования:"
echo "Файлов в оригинале: $(find /opt/zapret -type f | wc -l)"
echo "Файлов в копии: $(find opt/zapret -type f | wc -l)"
echo "Размер копии: $(du -sh opt/zapret | cut -f1)"
