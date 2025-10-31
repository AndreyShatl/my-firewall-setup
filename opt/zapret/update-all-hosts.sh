#!/bin/bash
echo "Обновление YouTube hostlist..."
/opt/zapret/ipset/create_ipset.sh /opt/zapret/ipset/youtube-hosts.txt youtube_hosts

echo "Обновление Discord hostlist..."
/opt/zapret/ipset/create_ipset.sh /opt/zapret/ipset/discord-hosts.txt discord_hosts

echo "Обновление Instagram hostlist..."
/opt/zapret/ipset/create_ipset.sh /opt/zapret/ipset/instagram-hosts.txt instagram_hosts

echo "Все hostlist обновлены!"
