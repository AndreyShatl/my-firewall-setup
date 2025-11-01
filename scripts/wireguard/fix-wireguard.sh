#!/bin/bash
set -e

echo "=== ДИАГНОСТИКА И ИСПРАВЛЕНИЕ WIREGUARD ==="

echo "🔍 Проверяем статус WireGuard..."
systemctl status wg-quick@wg0.service --no-pager -l || true

echo ""
echo "📋 Проверяем конфиг WireGuard..."
if [ -f "/etc/wireguard/wg0.conf" ]; then
    echo "✅ Конфиг существует"
    cat /etc/wireguard/wg0.conf
else
    echo "❌ Конфиг не существует"
fi

echo ""
echo "🌐 Проверяем сетевые интерфейсы..."
ip link show | grep wg0 || echo "Интерфейс wg0 не существует"

echo ""
echo "🔧 Проверяем наличие wireguard модуля..."
lsmod | grep wireguard || echo "Модуль wireguard не загружен"

echo ""
echo "🔄 Пересоздаем конфиг WireGuard..."
# Создаем новый ключ если нужно
if [ ! -f "/etc/wireguard/server_private.key" ]; then
    echo "📝 Генерируем новые ключи..."
    wg genkey | tee /etc/wireguard/server_private.key | wg pubkey > /etc/wireguard/server_public.key
    chmod 600 /etc/wireguard/server_private.key
fi

# Создаем конфиг
cat > /etc/wireguard/wg0.conf << 'WG_EOF'
[Interface]
PrivateKey = $(cat /etc/wireguard/server_private.key)
Address = 10.0.0.1/24
ListenPort = 51820
SaveConfig = false

# DNS для клиентов
PostUp = iptables -A FORWARD -i wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o eno1 -j MASQUERADE
PostDown = iptables -D FORWARD -i wg0 -j ACCEPT; iptables -t nat -D POSTROUTING -o eno1 -j MASQUERADE

# Пример клиента (замените на реальные ключи)
# [Peer]
# PublicKey = CLIENT_PUBKEY_HERE
# AllowedIPs = 10.0.0.2/32
WG_EOF

echo ""
echo "📁 Создан конфиг WireGuard:"
cat /etc/wireguard/wg0.conf

echo ""
echo "🔧 Проверяем синтаксис конфига..."
wg-quick check wg0

echo ""
echo "🚀 Пробуем запустить WireGuard..."
wg-quick up wg0

echo ""
echo "⏳ Ждем 2 секунды..."
sleep 2

echo ""
echo "🔍 Проверяем статус..."
wg show
ip addr show wg0 2>/dev/null && echo "✅ WG0 запущен" || echo "❌ WG0 не запущен"

echo ""
echo "🎯 Следующие шаги:"
echo "1. Добавьте клиентов в /etc/wireguard/wg0.conf"
echo "2. Перезапустите: systemctl restart wg-quick@wg0"
echo "3. Проверьте подключение клиентов"
