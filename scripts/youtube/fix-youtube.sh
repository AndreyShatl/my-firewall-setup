#!/bin/bash
set -e

echo "=== ИСПРАВЛЕНИЕ РАБОТЫ YOUTUBE ==="

echo "🛑 Останавливаем проблемную службу..."
systemctl stop zapret-aggressive

echo "🔧 Создаем исправленную службу с полной стратегией..."

cat > /etc/systemd/system/zapret-aggressive.service << 'SERVICE_EOF'
[Unit]
Description=Zapret Aggressive DPI Bypass for YouTube
After=network.target

[Service]
Type=simple
ExecStart=/opt/zapret/nfq/nfqws --qnum=201 --dpi-desync=fake,multisplit --dpi-desync-split-seqovl=681 --dpi-desync-split-pos=1 --dpi-desync-fooling=badseq --dpi-desync-badseq-increment=10000000 --dpi-desync-repeats=2 --dpi-desync-fake-tls-mod=rnd,dupsid,sni=fonts.google.com --filter-tcp=80,443 --hostlist=/opt/zapret/ipset/youtube-hosts.txt
Restart=always
RestartSec=5
User=root

[Install]
WantedBy=multi-user.target
SERVICE_EOF

echo "🔄 Перезагружаем демон systemd..."
systemctl daemon-reload

echo "🚀 Запускаем исправленную службу..."
systemctl start zapret-aggressive

echo "⏳ Ждем 3 секунды для стабилизации..."
sleep 3

echo "🔍 Проверяем статус службы..."
systemctl status zapret-aggressive --no-pager -l

echo "📋 Проверяем что процессы запустились..."
ps aux | grep nfqws | grep -v grep

echo "📝 Смотрим логи за последние 10 секунд..."
journalctl -u zapret-aggressive --since "10 seconds ago" --no-pager

echo ""
echo "🎯 Тестируем разные стратегии если нужно..."

# Создаем скрипт для тестирования альтернативных стратегий
cat > /tmp/test-youtube-strategies.sh << 'TEST_EOF'
#!/bin/bash
echo "=== ТЕСТИРОВАНИЕ АЛЬТЕРНАТИВНЫХ СТРАТЕГИЙ YOUTUBE ==="

STRATEGIES=(
    "--dpi-desync=fake,split2 --dpi-desync-any-protocol"
    "--dpi-desync=disorder --dpi-desync-disorder-forward=1"
    "--dpi-desync=split --dpi-desync-split-pos=2"
    "--dpi-desync=fake --dpi-desync-fake-tls-mod=rnd,sni=youtube.com"
    "--dpi-desync=split2 --dpi-desync-fooling=badseq --dpi-desync-badseq-increment=5000000"
)

for i in "${!STRATEGIES[@]}"; do
    echo ""
    echo "🧪 Тестируем стратегию $((i+1)): ${STRATEGIES[$i]}"
    
    # Останавливаем текущую службу
    systemctl stop zapret-aggressive
    
    # Создаем временную службу для тестирования
    cat > /etc/systemd/system/zapret-aggressive-test.service << EOF
[Unit]
Description=YouTube Test Strategy $((i+1))
After=network.target

[Service]
Type=simple
ExecStart=/opt/zapret/nfq/nfqws --qnum=201 ${STRATEGIES[$i]} --filter-tcp=80,443 --hostlist=/opt/zapret/ipset/youtube-hosts.txt
User=root

[Install]
WantedBy=multi-user.target
