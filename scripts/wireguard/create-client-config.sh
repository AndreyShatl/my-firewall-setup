#!/bin/bash

if [ -z "$1" ] || [ -z "$2" ]; then
    echo "Использование: $0 <client_ip> <client_private_key>"
    echo "Пример: $0 10.0.0.2 eCv5VpK... (приватный ключ клиента)"
    echo ""
    echo "Доступные IP из конфига: 10.0.0.2, 10.0.0.3, 10.0.0.4"
    echo "Публичные ключи сервера и пиров:"
    grep -A1 "PublicKey" /etc/wireguard/wg0.conf
    exit 1
fi

CLIENT_IP=$1
CLIENT_PRIVATE_KEY=$2
SERVER_PUBLIC_KEY="+CVNATzjIqk0H5GydqKVfmjDe/Lrn2GDsbj7x7OGTVo="
SERVER_IP=$(hostname -I | awk '{print $1}')

echo "=== СОЗДАНИЕ КОНФИГА КЛИЕНТА ==="
echo "IP клиента: $CLIENT_IP"
echo "IP сервера: $SERVER_IP"

cat > /etc/wireguard/client_${CLIENT_IP}.conf << CLIENT_EOF
[Interface]
PrivateKey = $CLIENT_PRIVATE_KEY
Address = $CLIENT_IP/24
DNS = 8.8.8.8, 1.1.1.1

[Peer]
PublicKey = $SERVER_PUBLIC_KEY
Endpoint = $SERVER_IP:51820
AllowedIPs = 0.0.0.0/0
CLIENT_EOF

echo ""
echo "✅ Конфиг создан: /etc/wireguard/client_${CLIENT_IP}.conf"
echo ""
echo "📜 Содержимое конфига:"
cat /etc/wireguard/client_${CLIENT_IP}.conf

echo ""
echo "🎯 QR код (если установлен qrencode):"
qrencode -t ansiutf8 < /etc/wireguard/client_${CLIENT_IP}.conf 2>/dev/null || echo "Установите qrencode: apt install qrencode"

echo ""
echo "🔑 Публичные ключи клиентов из серверного конфига:"
echo "10.0.0.2: Dipe1cnQnQCRa02Q/6qUxVUw+M3x5C9cWAWZir5BIhM="
echo "10.0.0.3: O8BC+VktsIiH1rC4RdPstP8uRxiCKHa93aXk+8eMtQ4="
echo "10.0.0.4: u00oaxWEguwV/NbQGfAcWc5sYHuq4VPVydMFTjB90QE="
