#!  /bin/bash

# Pouzite parametry jsou nasledujici:
program=${1}    # POVINNY parametr (parametr1) prikazove radky, urcuje ktery kanal spustit. Priklady hodnot: "ct1", "retro", "loop_waterfall".
quality=40    # nepovinny parametr (parametr2) prikazove radky, urcuje kvalitu streamu. Obvykle hodnoty: "20" = SD, "40" = HD. Vychozi = SD.


playlist=$HOME/.cache/sledovanitv_${program}

if [ -s ${playlist} ]; then

	file_time=$(( $(stat -t ${playlist} | cut -d" " -f 13) ))
	current_time=$(date +%s)

	stari=$(( current_time - 60 * 60 * 12 ))

	if [ ${file_time} -gt ${stari} ]; then
		HLS=${playlist}
	fi
fi

if [ -z "${HLS}" ]; then
	source `dirname $0`/sledovanitv-token.sh

	[ -f ${playlist} ] && rm ${playlist}
	wget -qO ${playlist}  "http://sledovanitv.cz/vlc/api-channel/${program}.m3u8?quality=${quality}&capabilities=h265,adaptive&PHPSESSID=${PHPSESSID}"
	
	sed -i -e "s/^noAccess-/http:\/\/sledovanitv.cz\/download\/noAccess-/" ${playlist} 
	
	HLS=${playlist}
fi

ffmpeg -nostats -loglevel 0 -protocol_whitelist "http,file,tcp" -i ${HLS} -c copy -map 0  -f mpegts pipe:1

#
