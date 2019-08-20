#!  /bin/bash

# Pouzite parametry jsou nasledujici:
program=${1}    # POVINNY parametr (parametr1) prikazove radky, urcuje ktery kanal spustit. Priklady hodnot: "ct1", "retro", "loop_waterfall".
quality=40    # nepovinny parametr (parametr2) prikazove radky, urcuje kvalitu streamu. Obvykle hodnoty: "20" = SD, "40" = HD. Vychozi = SD.

source `dirname $0`/sledovanitv-token.sh

playlist=$(wget -qO - "http://sledovanitv.cz/vlc/api-channel/${program}.m3u8?quality=${quality}&capabilities=h265,adaptive&PHPSESSID=${PHPSESSID}")

stream=$(echo ${playlist} | sed -e "s/\ /\n/g" | sed -n 3p)        # extrakce tretiho radku playlistu = adresa playlistu jiz pro konkretni stream

if [ -z "${stream}" ]; then
	echo "Nenasel se stream" >> /dev/stderr
	exit 2
fi

ffmpeg -nostats -loglevel 0 -re -fflags +genpts -i "${stream}" -f mpegts -vcodec copy -acodec copy pipe:1        # zajisteni vystupu raw TS datoveho streamu

