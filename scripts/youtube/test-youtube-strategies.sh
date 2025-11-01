#!/bin/bash
echo "=== ТЕСТИРОВАНИЕ АЛЬТЕРНАТИВНЫХ СТРАТЕГИЙ YOUTUBE ==="

STRATEGIES=(
    "--dpi-desync=fake,split2 --dpi-desync-any-protocol"
    "--dpi-desync=disorder --dpi-desync-disorder-forward=1"
    "--dpi-desync=split --dpi-desync-split-pos=2"
    "--dpi-desync=fake --dpi-desync-fake-tls-mod=rnd,sni=youtube.com"
    "--dpi-desync=split2 --dpi-desync-fooling=badseq --dpi-desync-badseq-increment=5000000"
)

echo "🛑 Останавливаем текущую службу..."
systemctl stop zapret-aggressive

for i in "${!STRATEGIES[@]}"; do
    echo ""
    echo "🧪 Тестируем стратегию $((i+1)): ${STRATEGIES[$i]}"
    
    # Создаем временную службу для тестирования
    cat > /etc/systemd/system/zapret-aggressive-test.service << SERVICE_EOF
[Unit]
Description=YouTube Test Strategy $((i+1))
After=network.target

[Service]
Type=simple
ExecStart=/opt/zapret/nfq/nfqws --qnum=201 ${STRATEGIES[$i]} --filter-tcp=80,443 --hostlist=/opt/zapret/ipset/youtube-hosts.txt
User=root

[Install]
WantedBy=multi-user.target
SERVICE_EOF
    
    systemctl daemon-reload
    systemctl start zapret-aggressive-test
    
    echo "⏳ Ожидаем 10 секунд... Проверьте YouTube в это время"
    sleep 10
    
    echo "📊 Статус:"
    systemctl status zapret-aggressive-test --no-pager -l | grep -E "(Active|Main PID)"
    
    # Останавливаем тестовую службу
    systemctl stop zapret-aggressive-test
    rm -f /etc/systemd/system/zapret-aggressive-test.service
    systemctl daemon-reload
    
    read -p "✅ Работает YouTube? (y/n): " answer
    if [[ $answer == "y" || $answer == "Y" ]]; then
        echo "🎉 Найдена рабочая стратегия! Сохраняем..."
        
        # Сохраняем рабочую стратегию в основную службу
        cat > /etc/systemd/system/zapret-aggressive.service << SERVICE_EOF
[Unit]
Description=Zapret Aggressive DPI Bypass for YouTube
After=network.target

[Service]
Type=simple
ExecStart=/opt/zapret/nfq/nfqws --qnum=201 ${STRATEGIES[$i]} --filter-tcp=80,443 --hostlist=/opt/zapret/ipset/youtube-hosts.txt
Restart=always
RestartSec=5
User=root

[Install]
WantedBy=multi-user.target
SERVICE_EOF
        
        systemctl daemon-reload
        systemctl start zapret-aggressive
        systemctl enable zapret-aggressive
        
        echo "✅ Рабочая стратегия сохранена в основную службу!"
        break
    fi
done

# Возвращаем основную службу если ни одна не сработала
systemctl start zapret-aggressive

echo "✅ Тестирование завершено!"
