#!  /bin/bash 

source $(dirname $0)/sledovanitv-token.sh

# Vytvarim novy autoconfigfile
echo "#EXTM3U"
IFS=$'\n'
for channel in $(wget -q -O- "https://sledovanitv.cz/api/playlist?PHPSESSID=${PHPSESSID}&quality=40&capabilities=h265%2Cadaptive"  | jq  -r '.channels[] | select (.locked=="none" and .type=="tv") | [.id,.name,.logoUrl,.url] | @text'); do
	id=$(echo $channel | jq -r '.[0]')
	label=$(echo $channel | jq -r '.[1]')
	icon=$(echo $channel | jq -r '.[2]')
	url=$(echo $channel | jq -r '.[3]')
	
	echo '#EXTINF:0 tvg-id="'${id}'" epg-id="'${id}'" tvg-name="'${label}'" tvg-logo="'${icon}'",'${label}
	echo 'pipe://ffmpeg -nostats -loglevel 0 -protocol_whitelist "https,tls,http,file,tcp" -i "'${url}'" -c copy -map 0  -f mpegts pipe:1'
done
