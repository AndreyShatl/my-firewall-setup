#!/bin/bash
echo "=== ШАГ 6: КОПИРОВАНИЕ КЛИЕНТОВ WIREGUARD ==="

cd /opt/my-firewall-setup

echo "Копируем папку clients..."
if [ -d "/opt/zapret/clients" ]; then
    cp -r /opt/zapret/clients/* opt/zapret/clients/ && echo "✅ clients/"
else
    echo "❌ Папка clients не найдена"
fi

echo "✅ Клиенты WireGuard скопированы"
