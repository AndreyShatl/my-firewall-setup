#!/bin/bash
set -e

echo "=== КОМПЛЕКСНОЕ ИСПРАВЛЕНИЕ YOUTUBE ==="

BACKUP_DIR="/opt/zapret/ipset/backup"
mkdir -p $BACKUP_DIR

echo "📝 Создаем расширенный список хостов YouTube..."
cp /opt/zapret/ipset/youtube-hosts.txt "$BACKUP_DIR/youtube-hosts_$(date +%Y%m%d-%H%M%S).bak"

cat > /opt/zapret/ipset/youtube-hosts.txt << 'HOSTS_EOF'
youtube.com
googlevideo.com
youtubei.googleapis.com
i.ytimg.com
yt3.ggpht.com
youtubekids.com
youtu.be
youtube-nocookie.com
ytimg.com
ggpht.com
wide-youtube.l.google.com
ytimg.l.google.com
youtubei.googleapis.com
youtubeembeddedplayer.googleapis.com
youtube-ui.l.google.com
yt-video-upload.l.google.com
jnn-pa.googleapis.com
HOSTS_EOF

echo "✅ Список хостов расширен. Исходный файл сохранен в $BACKUP_DIR"

echo ""
echo "🎯 Запускаем подбор стратегии для YouTube..."
echo "Служба zapret-aggressive будет останавливаться и перезапускаться с новыми параметрами."
echo "После запуска каждой стратегии у вас будет 20 секунд проверить YouTube в браузере."
echo ""

STRATEGIES=(
    "--dpi-desync=split2"
    "--dpi-desync=fake,split2 --dpi-desync-fake-tls-mod=rnd,sni=fonts.google.com"
    "--dpi-desync=fake,split2 --dpi-desync-any-protocol"
    "--dpi-desync=split2 --dpi-desync-split-pos=1"
    "--dpi-desync=disorder2"
    "--dpi-desync=fake --dpi-desync-fake-tls=/opt/zapret/files/fake/tls_clienthello_www_google_com.bin"
    "--dpi-desync=fake,disorder2 --dpi-desync-fooling=badseq --dpi-desync-badseq-increment=5000000"
)

for i in "${!STRATEGIES[@]}"; do
    echo ""
    echo "🧪 ТЕСТ СТРАТЕГИИ $((i+1))/${#STRATEGIES[@]}"
    echo "Параметры: ${STRATEGIES[$i]}"
    
    systemctl stop zapret-aggressive

    cat > /etc/systemd/system/zapret-aggressive.service << SERVICE_EOF
[Unit]
Description=Zapret Aggressive DPI Bypass for YouTube (Test Strategy $((i+1)))
After=network.target

[Service]
Type=simple
ExecStart=/opt/zapret/nfq/nfqws --qnum=201 ${STRATEGIES[$i]} --filter-tcp=80,443 --hostlist=/opt/zapret/ipset/youtube-hosts.txt
Restart=no
User=root

[Install]
WantedBy=multi-user.target
SERVICE_EOF

    systemctl daemon-reload
    systemctl start zapret-aggressive
    echo "✅ Служба перезапущена"

    echo "⏳ Ожидаем 5 секунд для стабилизации..."
    sleep 5

    echo "🔍 Статус службы:"
    systemctl status zapret-aggressive --no-pager -l | grep -E "(Active|Main PID|failed)"

    echo "⏰ Проверьте работу YouTube в браузере в течение 20 секунд..."
    for sec in {20..1}; do
        echo -ne "\rОсталось: ${sec} сек (Нажмите Ctrl+C чтобы прервать, Y если работает, N если не работает)"
        sleep 1
    done
    echo -ne "\r" 

    read -p "✅ Работает YouTube? (y/n): " answer
    if [[ $answer == "y" || $answer == "Y" ]]; then
        echo ""
        echo "🎉 ПОЗДРАВЛЯЮ! Найдена рабочая стратегия!"
        echo "Стратегия $((i+1)): ${STRATEGIES[$i]}"
        
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

        echo "✅ Рабочая стратегия сохранена в службу zapret-aggressive и добавлена в автозагрузку!"
        echo "📋 Параметры для ручного использования:"
        echo "/opt/zapret/nfq/nfqws --qnum=201 ${STRATEGIES[$i]} --filter-tcp=80,443 --hostlist=/opt/zapret/ipset/youtube-hosts.txt"
        exit 0
    fi
    
    echo "❌ Стратегия $((i+1)) не сработала, пробуем следующую..."
    echo ""
done

echo ""
echo "⚠️  Ни одна из базовых стратегий не сработала."
echo "Рекомендуется провести расширенную диагностику:"
echo "1. Проверить работу QUIC в браузере (F12 → Вкладка 'Сеть' → столбец 'Протокол')"
echo "2. Принудительно отключить QUIC в настройках браузера"
echo "3. Проверить наличие актуальных TLS фейков в /opt/zapret/files/fake/"
echo "4. Использовать блокировку QUIC на уровне маршрутизатора[citation:2]"
