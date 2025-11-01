#!/bin/bash
echo "=== ШАГ 5: КОПИРОВАНИЕ ZAPRET (СПИСКИ ХОСТОВ) ==="

cd /opt/my-firewall-setup

echo "Копируем папку ipset..."
if [ -d "/opt/zapret/ipset" ]; then
    cp -r /opt/zapret/ipset/* opt/zapret/ipset/ && echo "✅ ipset/"
else
    echo "❌ Папка ipset не найдена"
fi

echo "✅ Списки хостов скопированы"
