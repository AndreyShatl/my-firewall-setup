#!/bin/bash
echo "=== ОТКЛЮЧЕНИЕ IPV6 ДЛЯ YOUTUBE ==="

echo "🔧 Отключаем IPv6 временно..."
sysctl -w net.ipv6.conf.all.disable_ipv6=1
sysctl -w net.ipv6.conf.default.disable_ipv6=1

echo "📝 Добавляем в автозагрузку..."
echo "net.ipv6.conf.all.disable_ipv6=1" >> /etc/sysctl.conf
echo "net.ipv6.conf.default.disable_ipv6=1" >> /etc/sysctl.conf

echo "🔍 Проверяем статус IPv6..."
ip a | grep inet6 || echo "✅ IPv6 отключен"

echo "🎯 Рекомендация: также отключите IPv6 на клиентах WireGuard"
