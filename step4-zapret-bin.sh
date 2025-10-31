#!/bin/bash
echo "=== ШАГ 4: КОПИРОВАНИЕ ZAPRET (БИНАРНЫЕ ФАЙЛЫ) ==="

cd /opt/my-firewall-setup

echo "Копируем папку nfq..."
if [ -d "/opt/zapret/nfq" ]; then
    cp -r /opt/zapret/nfq/* opt/zapret/nfq/ && echo "✅ nfq/"
else
    echo "❌ Папка nfq не найдена"
fi

echo "✅ Бинарные файлы Zapret скопированы"
