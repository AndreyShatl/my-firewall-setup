#!/bin/bash
echo "=== ШАГ 2: КОПИРОВАНИЕ SYSTEMD СЛУЖБ ==="

cd /opt/my-firewall-setup

echo "Копируем службы Zapret..."
cp /etc/systemd/system/zapret-basic.service etc/systemd/system/ 2>/dev/null && echo "✅ zapret-basic.service" || echo "❌ zapret-basic.service не найден"
cp /etc/systemd/system/zapret-aggressive.service etc/systemd/system/ 2>/dev/null && echo "✅ zapret-aggressive.service" || echo "❌ zapret-aggressive.service не найден"

echo "Копируем службу WireGuard..."
if [ -f "/etc/systemd/system/wg-quick@wg0.service" ]; then
    cp /etc/systemd/system/wg-quick@wg0.service etc/systemd/system/ && echo "✅ wg-quick@wg0.service"
elif [ -f "/usr/lib/systemd/system/wg-quick@.service" ]; then
    cp /usr/lib/systemd/system/wg-quick@.service etc/systemd/system/ && echo "✅ wg-quick@.service (из /usr/lib)"
else
    echo "⚠️ Служба WireGuard не найдена"
fi

echo "✅ Службы systemd скопированы"
