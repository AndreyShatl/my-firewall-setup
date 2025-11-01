#!/bin/bash
set -e

echo "=== ПЕРЕКЛЮЧЕНИЕ НА РЕЗЕРВНУЮ КОПИЮ СИСТЕМЫ ==="
echo "Версия: 1.00"
echo ""

# Функция для логирования
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

echo "🛑 Останавливаем все службы..."
systemctl stop zapret-basic 2>/dev/null && log "✅ zapret-basic остановлен" || log "⚠️ zapret-basic не запущен"
systemctl stop zapret-aggressive 2>/dev/null && log "✅ zapret-aggressive остановлен" || log "⚠️ zapret-aggressive не запущен"
systemctl stop wg-quick@wg0 2>/dev/null && log "✅ wg-quick@wg0 остановлен" || log "⚠️ wg-quick@wg0 не запущен"

echo ""
echo "📦 Создаем временную резервную копию текущей системы..."
BACKUP_DIR="/tmp/old-system-backup-$(date +%Y%m%d-%H%M%S)"
mkdir -p $BACKUP_DIR

# Копируем текущие конфиги
cp -r /etc/systemd/system/zapret* $BACKUP_DIR/ 2>/dev/null || log "⚠️ Не удалось скопировать службы zapret"
cp /etc/wireguard/wg0.conf $BACKUP_DIR/ 2>/dev/null || log "⚠️ Не удалось скопировать wg0.conf"
cp /etc/nftables.conf $BACKUP_DIR/ 2>/dev/null || log "⚠️ Не удалось скопировать nftables.conf"
cp /etc/dhcp/dhcpd.conf $BACKUP_DIR/ 2>/dev/null || log "⚠️ Не удалось скопировать dhcpd.conf"
cp /etc/dnsmasq.conf $BACKUP_DIR/ 2>/dev/null || log "⚠️ Не удалось скопировать dnsmasq.conf"

echo ""
echo "🔧 Развертываем систему из резервной копии..."
cd /opt/my-firewall-setup

# Развертываем службы systemd
echo "Развертываем службы systemd..."
cp etc/systemd/system/zapret-basic.service /etc/systemd/system/ && log "✅ zapret-basic.service развернут"
cp etc/systemd/system/zapret-aggressive.service /etc/systemd/system/ && log "✅ zapret-aggressive.service развернут"
if [ -f "etc/systemd/system/wg-quick@.service" ]; then
    cp etc/systemd/system/wg-quick@.service /etc/systemd/system/ && log "✅ wg-quick@.service развернут"
fi

# Развертываем сетевые конфиги
echo "Развертываем сетевые конфиги..."
cp etc/wireguard/wg0.conf /etc/wireguard/ && log "✅ wg0.conf развернут"
cp etc/nftables.conf /etc/ && log "✅ nftables.conf развернут"
cp etc/dhcp/dhcpd.conf /etc/dhcp/ && log "✅ dhcpd.conf развернут"
cp etc/dnsmasq.conf /etc/ && log "✅ dnsmasq.conf развернут"

# Развертываем Zapret
echo "Развертываем Zapret..."
rm -rf /opt/zapret.old
mv /opt/zapret /opt/zapret.old 2>/dev/null && log "✅ Старый /opt/zapret перемещен в /opt/zapret.old"
cp -r opt/zapret /opt/ && log "✅ Zapret развернут"

# Даем права на исполнение скриптам
chmod +x /opt/zapret/*.sh 2>/dev/null && log "✅ Права на скрипты установлены"

echo ""
echo "🔄 Перезагружаем systemd..."
systemctl daemon-reload && log "✅ Systemd демон перезагружен"

echo ""
echo "🚀 Запускаем службы..."
systemctl start zapret-basic && log "✅ zapret-basic запущен" || log "❌ Ошибка запуска zapret-basic"
systemctl start zapret-aggressive && log "✅ zapret-aggressive запущен" || log "❌ Ошибка запуска zapret-aggressive"
systemctl start wg-quick@wg0 && log "✅ wg-quick@wg0 запущен" || log "❌ Ошибка запуска wg-quick@wg0"

echo ""
echo "🔍 Проверяем работоспособность..."
sleep 3

echo "Статус служб:"
systemctl is-active zapret-basic >/dev/null && echo "✅ zapret-basic: АКТИВЕН" || echo "❌ zapret-basic: НЕ АКТИВЕН"
systemctl is-active zapret-aggressive >/dev/null && echo "✅ zapret-aggressive: АКТИВЕН" || echo "❌ zapret-aggressive: НЕ АКТИВЕН"
systemctl is-active wg-quick@wg0 >/dev/null && echo "✅ wg-quick@wg0: АКТИВЕН" || echo "❌ wg-quick@wg0: НЕ АКТИВЕН"

echo ""
echo "🌐 Проверяем сетевые интерфейсы:"
ip link show wg0 >/dev/null 2>&1 && echo "✅ Интерфейс wg0: СУЩЕСТВУЕТ" || echo "❌ Интерфейс wg0: ОТСУТСТВУЕТ"

echo ""
echo "📊 Итоги переключения:"
echo "Резервная копия старой системы: $BACKUP_DIR"
echo "Старый Zapret перемещен в: /opt/zapret.old"
echo ""
echo "🎯 Дальнейшие действия:"
echo "1. Проверьте работу системы в течение 10-15 минут"
echo "2. Если все работает нормально, удалите старые файлы:"
echo "   sudo rm -rf /opt/zapret.old"
echo "   sudo rm -rf $BACKUP_DIR"
echo "3. Если есть проблемы, верните старую систему:"
echo "   sudo ./restore-old-system.sh"
