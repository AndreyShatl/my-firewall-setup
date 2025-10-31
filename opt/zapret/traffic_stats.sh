#!/bin/bash
echo "=== Статистика трафика по очередям ==="
echo "Очередь 200 (базовый обход):"
nft list table inet zapret | grep "queue to 200" -A 1 | grep counter
echo ""
echo "Очередь 201 (агрессивный обход для YouTube):"
nft list table inet zapret | grep "queue to 201" -A 1 | grep counter
echo ""
echo "Логи zapret-basic:"
journalctl -u zapret-basic -n 5 --no-pager
echo ""
echo "Логи zapret-aggressive:"
journalctl -u zapret-aggressive -n 5 --no-pager
