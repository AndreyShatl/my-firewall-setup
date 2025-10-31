#!/bin/bash
echo "=== Список клиентов WireGuard ==="
for client_dir in /opt/zapret/clients/*; do
    if [ -d "$client_dir" ]; then
        client_name=$(basename "$client_dir")
        client_ip=$(grep "Address" "$client_dir/wg0.conf" | cut -d'=' -f2 | tr -d ' ')
        echo "Клиент: $client_name, IP: $client_ip"
    fi
done
echo ""
echo "Текущие пиры в WireGuard:"
wg show wg0
