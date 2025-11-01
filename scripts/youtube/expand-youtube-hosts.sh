#!/bin/bash
set -e

echo "=== РАСШИРЕНИЕ СПИСКА ХОСТОВ YOUTUBE ==="

# Создаем резервную копию
BACKUP_DIR="/opt/zapret/ipset/backup"
mkdir -p $BACKUP_DIR
cp /opt/zapret/ipset/youtube-hosts.txt "$BACKUP_DIR/youtube-hosts_$(date +%Y%m%d-%H%M%S).bak"

echo "📝 Добавляем все возможные домены YouTube..."

# Основной список доменов YouTube
cat >> /opt/zapret/ipset/youtube-hosts.txt << 'HOSTS_EOF'

# Основные домены YouTube
youtube.com
www.youtube.com
m.youtube.com
youtu.be
gaming.youtube.com
music.youtube.com
kids.youtube.com
www.youtubekids.com
youtubekids.com

# API и сервисы YouTube
youtubei.googleapis.com
www.youtube-nocookie.com
youtube-nocookie.com
youtube.googleapis.com
youtubeeducation.com
yt3.ggpht.com
yt.be

# CDN и медиа хосты
googlevideo.com
r*.googlevideo.com
r1---sn-*.googlevideo.com
r2---sn-*.googlevideo.com
r3---sn-*.googlevideo.com
r4---sn-*.googlevideo.com
r5---sn-*.googlevideo.com
r6---sn-*.googlevideo.com
r7---sn-*.googlevideo.com
r8---sn-*.googlevideo.com

# Статические ресурсы
i.ytimg.com
i1.ytimg.com
i2.ytimg.com
i3.ytimg.com
i4.ytimg.com
s.ytimg.com
img.youtube.com

# Google сервисы для YouTube
googleapis.com
ggpht.com
gstatic.com
google.com
www.google.com

# Дополнительные сервисы
accounts.youtube.com
studio.youtube.com
creators.youtube.com
HOSTS_EOF

echo "✅ Домены добавлены в /opt/zapret/ipset/youtube-hosts.txt"

# Удаляем дубликаты и сортируем
sort -u /opt/zapret/ipset/youtube-hosts.txt -o /opt/zapret/ipset/youtube-hosts.txt

echo "📊 Статистика после добавления:"
echo "Количество хостов: $(wc -l < /opt/zapret/ipset/youtube-hosts.txt)"
echo "Размер файла: $(du -h /opt/zapret/ipset/youtube-hosts.txt | cut -f1)"

echo ""
echo "🔄 Перезапускаем службу zapret-aggressive..."
systemctl restart zapret-aggressive

echo "⏳ Ждем 5 секунд..."
sleep 5

echo "🔍 Проверяем статус..."
systemctl status zapret-aggressive --no-pager -l

echo ""
echo "🎯 Проверьте YouTube теперь!"
echo "Если все еще не работает, возможно нужна другая стратегия обхода."
