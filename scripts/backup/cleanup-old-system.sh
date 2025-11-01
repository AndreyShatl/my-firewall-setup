#!/bin/bash

echo "=== ОЧИСТКА СТАРОЙ СИСТЕМЫ ==="

echo "🗑️ Удаляем старые файлы..."
if [ -d "/opt/zapret.old" ]; then
    rm -rf /opt/zapret.old
    echo "✅ /opt/zapret.old удален"
else
    echo "ℹ️ /opt/zapret.old не найден"
fi

echo "🗑️ Удаляем резервные копии..."
BACKUP_COUNT=0
for backup in /tmp/old-system-backup-*; do
    if [ -d "$backup" ]; then
        rm -rf "$backup"
        BACKUP_COUNT=$((BACKUP_COUNT+1))
    fi
done

if [ $BACKUP_COUNT -gt 0 ]; then
    echo "✅ Удалено $BACKUP_COUNT резервных копий"
else
    echo "ℹ️ Резервные копии не найдены"
fi

echo "✅ Очистка завершена!"
echo ""
echo "🎯 Текущая структура:"
echo "Рабочая система: /opt/zapret (из резервной копии)"
echo "Резервная копия проекта: /opt/my-firewall-setup"
echo "Git репозиторий: /opt/my-firewall-setup (синхронизирован с GitHub)"
