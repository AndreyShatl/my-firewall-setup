#!/bin/bash
set -e

echo "=== ПОЛНАЯ ОЧИСТКА И ПЕРЕУСТАНОВКА ==="

echo "🛑 Останавливаем все службы..."
systemctl stop zapret-basic 2>/dev/null || true
systemctl stop zapret-aggressive 2>/dev/null || true
systemctl stop wg-quick@wg0 2>/dev/null || true

echo "🔪 Убиваем все процессы..."
pkill nfqws 2>/dev/null || true
pkill wireguard 2>/dev/null || true

echo "🧹 Удаляем старые файлы..."
# Удаляем старые версии zapret
rm -rf /opt/zapret 2>/dev/null || true

# Удаляем старые конфиги служб
rm -f /etc/systemd/system/zapret-*.service 2>/dev/null || true

# Удаляем старые конфиги wireguard
rm -f /etc/wireguard/wg0.conf 2>/dev/null || true

# Очищаем nftables
nft flush ruleset 2>/dev/null || true

echo "📦 Проверяем структуру проекта в /opt/my-firewall-setup..."
ls -la /opt/my-firewall-setup/

echo ""
echo "🔄 Перезагружаем systemd..."
systemctl daemon-reload

echo ""
echo "✅ Очистка завершена!"
echo ""
echo "🎯 Теперь нужно:"
echo "1. Переустановить zapret из /opt/my-firewall-setup/"
echo "2. Настроить WireGuard заново"
echo "3. Настроить nftables правила"
echo ""
echo "Запустите: ./setup-zapret-from-project.sh"
