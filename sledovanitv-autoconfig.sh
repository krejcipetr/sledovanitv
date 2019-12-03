#!  /bin/bash 

source $(dirname $0)/sledovanitv-token.sh

# Vytvarim novy autoconfigfile
echo "#EXTM3U"
wget -q -O- "https://sledovanitv.cz/api/playlist?PHPSESSID=${SLEDOVANITVID}&quality=40&capabilities=h265%2Cadaptive"  | jq  -r '.channels[] | select (.locked=="none" and .type=="tv") | "#EXTINF:0 tvg-id=\"\(.id)\" epg-id=\"\(.id)\" tvg-name=\"\(.name)\" tvg-logo=\"\(.logoUrl)\",\(.name)\npipe://ffmpeg -nostats -loglevel 0 -protocol_whitelist \"https,tls,http,file,tcp\" -i \"\(.url)\" -c copy -map 0  -f mpegts pipe:1"'
