# Система Обхода DPI - Версия 1.00

Полная система обхода Deep Packet Inspection с использованием Zapret и WireGuard.

## Компоненты:
- Zapret с двумя очередями (200 - базовая, 201 - агрессивная для YouTube)
- WireGuard VPN сервер
- DHCP и DNS серверы
- NFTables для фильтрации трафика

## Структура:
opt/my-firewall-setup/
├── etc/ # Конфигурационные файлы
│ ├── systemd/system/ # Службы systemd
│ ├── wireguard/ # Конфиг WireGuard
│ ├── dhcp/ # Конфиг DHCP
│ └── nftables.conf # Правила фильтрации
└── opt/zapret/ # Основное ПО обхода DPI
