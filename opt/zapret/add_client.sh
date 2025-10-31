#!/bin/bash

if [ -z "$1" ]; then
    echo "Укажите имя клиента: $0 client_name"
    exit 1
fi

CLIENT_NAME=$1
CLIENT_DIR="/opt/zapret/clients/$CLIENT_NAME"
SERVER_PUBLIC_KEY=$(wg show wg0 public-key)  # Автоматически получаем публичный ключ сервера
SERVER_IP="95.31.136.109"  # Ваш IP сервера

# Создаем папку для клиента
mkdir -p $CLIENT_DIR

# Генерируем ключи для клиента
CLIENT_PRIVATE_KEY=$(wg genkey)
CLIENT_PUBLIC_KEY=$(echo $CLIENT_PRIVATE_KEY | wg pubkey)

# Сохраняем ключи
echo "$CLIENT_PRIVATE_KEY" > $CLIENT_DIR/private.key
echo "$CLIENT_PUBLIC_KEY" > $CLIENT_DIR/public.key
chmod 600 $CLIENT_DIR/private.key

# Определяем IP клиента (начинаем с 10.0.0.2 и увеличиваем для каждого нового клиента)
CLIENT_COUNT=$(find /opt/zapret/clients -maxdepth 1 -type d | wc -l)
CLIENT_IP="10.0.0.$((2 + $CLIENT_COUNT - 1))"

# Создаем конфигурационный файл для клиента
cat > $CLIENT_DIR/wg0.conf << CLIENT_EOF
[Interface]
PrivateKey = $CLIENT_PRIVATE_KEY
Address = $CLIENT_IP/24
DNS = 8.8.8.8

[Peer]
PublicKey = $SERVER_PUBLIC_KEY
Endpoint = $SERVER_IP:51820
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25
CLIENT_EOF

# Добавляем клиента на сервер
wg set wg0 peer "$CLIENT_PUBLIC_KEY" allowed-ips "$CLIENT_IP/32"

# Сохраняем конфигурацию сервера
wg-quick save wg0

# Показываем информацию
echo "=== Конфигурация для клиента $CLIENT_NAME ==="
echo "Папка: $CLIENT_DIR"
echo "IP адрес: $CLIENT_IP"
echo "Публичный ключ клиента: $CLIENT_PUBLIC_KEY"
echo ""

# Показываем QR-код
echo "QR-код для подключения:"
qrencode -t ansiutf8 < "$CLIENT_DIR/wg0.conf"
echo ""

# Показываем текстовый конфиг
echo "Текстовый конфиг:"
cat "$CLIENT_DIR/wg0.conf"
