#!/bin/bash
echo "=== ШАГ 22: СОЗДАНИЕ ДОКУМЕНТАЦИИ ПРОЕКТА ==="

cd /opt/my-firewall-setup

echo "📄 Создаем основной README.md..."

cat > README.md << 'README_EOF'
# Система Обхода DPI - Версия 1.00

## 📋 Описание проекта
Полная система обхода Deep Packet Inspection (DPI) с использованием Zapret, WireGuard и дополнительных сетевых сервисов.

## 🏗️ Архитектура системы
Система использует двухуровневый подход:

Очередь 200: Базовые методы обхода для общего трафика

Очередь 201: Агрессивные методы для YouTube и сложных случаев

## 🚀 Быстрый старт

### Предварительные требования
- Debian/Ubuntu сервер
- Привилегии root
- Настроенные сетевые интерфейсы

### Установка
```bash
# Клонировать репозиторий
git clone https://github.com/your-username/my-firewall-setup.git
cd my-firewall-setup

# Развертывание системы
./deploy-system.sh
/opt/my-firewall-setup/
├── etc/                    # Конфигурационные файлы системы
│   ├── systemd/system/    # Службы systemd
│   │   ├── zapret-basic.service
│   │   ├── zapret-aggressive.service
│   │   └── wg-quick@.service
│   ├── wireguard/         # Конфигурация WireGuard
│   │   └── wg0.conf
│   ├── dhcp/              # Конфиг DHCP сервера
│   │   └── dhcpd.conf
│   ├── nftables.conf      # Правила фильтрации
│   └── dnsmasq.conf       # DNS сервер
└── opt/zapret/           # Основное ПО обхода DPI
    ├── nfq/              # Бинарные файлы и исходный код nfqws
    ├── ipset/            # Списки блокируемых хостов
    ├── clients/          # Конфиги клиентов WireGuard
    ├── files/            # Дополнительные файлы
    ├── tpws/             # TPWS компоненты
    └── *.sh              # Скрипты управления
🔧 Systemd Службы
Zapret Basic (Очередь 200)
Назначение: Базовый обход DPI для общего трафика

Файл: etc/systemd/system/zapret-basic.service

Команда запуска: /opt/zapret/nfq/nfqws --qnum=200 --dpi-desync=fake --filter-tcp=80,443 --hostlist=/opt/zapret/ipset/zapret-hosts-user.txt

Статус: systemctl status zapret-basic

Zapret Aggressive (Очередь 201)
Назначение: Агрессивный обход для YouTube

Файл: etc/systemd/system/zapret-aggressive.service

Команда запуска: /opt/zapret/nfq/nfqws --qnum=201 --dpi-desync=fake,multisplit --dpi-desync-split-seqovl=681 --dpi-desync-split-pos=1 --dpi-desync-fooling=badseq --dpi-desync-badseq-increment=10000000 --dpi-desync-repeats=2 --dpi-desync-fake-tls-mod=rnd,dupsid,sni=fonts.google.com --filter-tcp=80,443 --hostlist=/opt/zapret/ipset/youtube-hosts.txt

Статус: systemctl status zapret-aggressive

WireGuard
Назначение: VPN туннель

Файл: etc/wireguard/wg0.conf

Статус: systemctl status wg-quick@wg0

🌐 Сетевые настройки
NFTables
Файл: etc/nftables.conf

Назначение: Фильтрация и маршрутизация трафика

DHCP Сервер
Файл: etc/dhcp/dhcpd.conf

Назначение: Раздача IP-адресов клиентам

DNS Сервер (DNSmasq)
Файл: etc/dnsmasq.conf

Назначение: DNS кэширование и разрешение имен

# Просмотр логов Zapret
journalctl -u zapret-basic -f
journalctl -u zapret-aggressive -f

# Просмотр логов WireGuard
journalctl -u wg-quick@wg0 -f

# Статистика трафика
/opt/zapret/traffic_stats.sh

🔄 Процесс обновления
Резервное копирование: ./backup-system.sh

Тестирование изменений: На тестовой очереди

Развертывание: ./deploy-system.sh

Валидация: Проверка работоспособности

🆘 Устранение неисправностей
Проверка статуса служб:
systemctl status zapret-basic
systemctl status zapret-aggressive
systemctl status wg-quick@wg0

Проверка сетевых интерфейсов:
ip link show wg0
iptables -t mangle -L | grep NFQUEUE
Система проверена и работает на Debian. Версия 1.00
README_EOF

echo "📋 Создаем файл версии..."
cat > VERSION << 'VERSION_EOF'
Версия: 1.00
Дата сборки: $(date)
Статус: Stable
Архитектура: Debian Linux
Компоненты:

Zapret с очередями 200/201

WireGuard VPN

DHCP сервер

DNS сервер (DNSmasq)

NFTables
VERSION_EOF

echo "✅ Документация создана!"
echo ""
echo "📄 Файлы:"
echo " - README.md"
echo " - VERSION"
