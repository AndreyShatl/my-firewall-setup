#!/bin/bash
set -e

echo "=== ВОССТАНОВЛЕНИЕ СТАРОЙ СИСТЕМЫ ==="

# Находим последнюю резервную копию
BACKUP_DIR=$(ls -d /tmp/old-system-backup-* 2>/dev/null | tail -1)

if [ -z "$BACKUP_DIR" ]; then
    echo "❌ Резервные копии не найдены!"
    exit 1
fi

echo "Восстанавливаем из: $BACKUP_DIR"

echo "🛑 Останавливаем службы..."
systemctl stop zapret-basic zapret-aggressive wg-quick@wg0 2>/dev/null

echo "🔧 Восстанавливаем конфиги..."
# Восстанавливаем службы
cp $BACKUP_DIR/zapret-basic.service /etc/systemd/system/ 2>/dev/null && echo "✅ zapret-basic.service восстановлен"
cp $BACKUP_DIR/zapret-aggressive.service /etc/systemd/system/ 2>/dev/null && echo "✅ zapret-aggressive.service восстановлен"

# Восстанавливаем сетевые конфиги
cp $BACKUP_DIR/wg0.conf /etc/wireguard/ 2>/dev/null && echo "✅ wg0.conf восстановлен"
cp $BACKUP_DIR/nftables.conf /etc/ 2>/dev/null && echo "✅ nftables.conf восстановлен"
cp $BACKUP_DIR/dhcpd.conf /etc/dhcp/ 2>/dev/null && echo "✅ dhcpd.conf восстановлен"
cp $BACKUP_DIR/dnsmasq.conf /etc/ 2>/dev/null && echo "✅ dnsmasq.conf восстановлен"

# Восстанавливаем старый Zapret если есть
if [ -d "/opt/zapret.old" ]; then
    rm -rf /opt/zapret
    mv /opt/zapret.old /opt/zapret
    echo "✅ Старый Zapret восстановлен"
fi

echo "🔄 Перезагружаем systemd..."
systemctl daemon-reload

echo "🚀 Запускаем службы..."
systemctl start zapret-basic zapret-aggressive wg-quick@wg0

echo "🔍 Проверяем статус..."
sleep 2
systemctl is-active zapret-basic >/dev/null && echo "✅ zapret-basic: АКТИВЕН" || echo "❌ zapret-basic: НЕ АКТИВЕН"
systemctl is-active zapret-aggressive >/dev/null && echo "✅ zapret-aggressive: АКТИВЕН" || echo "❌ zapret-aggressive: НЕ АКТИВЕН"
systemctl is-active wg-quick@wg0 >/dev/null && echo "✅ wg-quick@wg0: АКТИВЕН" || echo "❌ wg-quick@wg0: НЕ АКТИВЕН"

echo "✅ Восстановление завершено!"
