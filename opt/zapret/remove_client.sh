#!/bin/bash
if [ -z "$1" ]; then
    echo "Укажите имя клиента: $0 client_name"
    exit 1
fi

CLIENT_NAME=$1
CLIENT_DIR="/opt/zapret/clients/$CLIENT_NAME"

if [ ! -d "$CLIENT_DIR" ]; then
    echo "Клиент $CLIENT_NAME не найден"
    exit 1
fi

# Получаем публичный ключ клиента
CLIENT_PUBLIC_KEY=$(cat "$CLIENT_DIR/public.key")

# Удаляем клиента из WireGuard
wg set wg0 peer "$CLIENT_PUBLIC_KEY" remove

# Сохраняем конфигурацию
wg-quick save wg0

# Удаляем папку клиента
rm -rf "$CLIENT_DIR"

echo "Клиент $CLIENT_NAME удален"
