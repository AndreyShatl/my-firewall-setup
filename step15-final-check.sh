#!/bin/bash
echo "=== ШАГ 15: ФИНАЛЬНАЯ ПРОВЕРКА ПОСЛЕ ИСПРАВЛЕНИЙ ==="

cd /opt/my-firewall-setup

echo "🔍 Сравниваем количество файлов:"
orig_nfq=$(find /opt/zapret/nfq -type f | wc -l)
copy_nfq=$(find opt/zapret/nfq -type f | wc -l)
echo "  nfq:   оригинал $orig_nfq, копия $copy_nfq"

orig_ipset=$(find /opt/zapret/ipset -type f | wc -l) 
copy_ipset=$(find opt/zapret/ipset -type f | wc -l)
echo "  ipset: оригинал $orig_ipset, копия $copy_ipset"

orig_clients=$(find /opt/zapret/clients -type f | wc -l)
copy_clients=$(find opt/zapret/clients -type f | wc -l)
echo "  clients: оригинал $orig_clients, копия $copy_clients"

echo ""
echo "✅ Критические файлы:"
[ -f "opt/zapret/nfq/nfqws" ] && echo "  ✅ nfqws: СУЩЕСТВУЕТ" || echo "  ❌ nfqws: ОТСУТСТВУЕТ"
[ -x "opt/zapret/nfq/nfqws" ] && echo "  ✅ nfqws: ИСПОЛНЯЕМЫЙ" || echo "  ❌ nfqws: НЕ ИСПОЛНЯЕМЫЙ"

echo ""
echo "📊 Общая статистика:"
echo "Оригинал: $(find /opt/zapret -type f | wc -l) файлов, $(du -sh /opt/zapret | cut -f1)"
echo "Копия:    $(find /opt/my-firewall-setup -type f | wc -l) файлов, $(du -sh /opt/my-firewall-setup | cut -f1)"

echo ""
if [ "$(find /opt/zapret -type f | wc -l)" -eq "$(find /opt/my-firewall-setup -type f | wc -l)" ]; then
    echo "🎉 УРА! Количество файлов совпадает!"
    echo "Можно переходить к созданию Git репозитория."
else
    echo "⚠️  Внимание: количество файлов все еще не совпадает."
    echo "Нужно дополнительное investigation."
fi
