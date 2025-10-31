#!/bin/bash
echo "=== ШАГ 7: КОПИРОВАНИЕ СКРИПТОВ ==="

cd /opt/my-firewall-setup

echo "Копируем скрипты из /opt/zapret/..."
for script in /opt/zapret/*.sh; do
    if [ -f "$script" ]; then
        cp "$script" opt/zapret/ && echo "✅ $(basename $script)"
    fi
done

echo "✅ Скрипты скопированы"
