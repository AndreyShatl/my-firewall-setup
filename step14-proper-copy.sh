#!/bin/bash
echo "=== ШАГ 14: ПРАВИЛЬНОЕ КОПИРОВАНИЕ С СОХРАНЕНИЕМ СТРУКТУРЫ ==="

cd /opt/my-firewall-setup

# Функция для безопасного копирования с проверкой
safe_copy_dir() {
    local src=$1
    local dest=$2
    local desc=$3
    
    echo "🔄 Копируем $desc..."
    if [ -d "$src" ]; then
        # Очищаем целевую директорию
        rm -rf "$dest"/*
        
        # Копируем с сохранением прав и структуры
        if cp -r "$src"/. "$dest"/ 2>/dev/null; then
            local file_count=$(find "$dest" -type f | wc -l)
            echo "✅ $desc: $file_count файлов скопировано"
            return 0
        else
            echo "❌ Ошибка копирования: $desc"
            return 1
        fi
    else
        echo "❌ Источник не найден: $src"
        return 2
    fi
}

echo "🧹 Начинаем полное перекопирование..."

# Копируем основные директории
safe_copy_dir "/opt/zapret/nfq" "opt/zapret/nfq" "nfq"
safe_copy_dir "/opt/zapret/ipset" "opt/zapret/ipset" "ipset" 
safe_copy_dir "/opt/zapret/clients" "opt/zapret/clients" "clients"

echo ""
echo "🔍 Проверяем критические файлы после копирования:"

critical_files=(
    "opt/zapret/nfq/nfqws"
    "opt/zapret/ipset/zapret-hosts-user.txt"
    "opt/zapret/ipset/youtube-hosts.txt"
    "opt/zapret/clients/test_client/wg0.conf"
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
echo "📊 Итоговая статистика:"
echo "Всего файлов в копии: $(find . -type f | wc -l)"
echo "Размер копии: $(du -sh . | cut -f1)"

echo ""
echo "📁 Структура основных папок:"
for dir in nfq ipset clients; do
    if [ -d "opt/zapret/$dir" ]; then
        count=$(find "opt/zapret/$dir" -type f | wc -l)
        echo "  opt/zapret/$dir: $count файлов"
    fi
done
