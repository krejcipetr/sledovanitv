#!  /bin/bash 

source $(dirname $0)/sledovanitv-token.sh

FILETMP=${cachedir}/sledovanitv_playlist

# Nacti playlist
CAPABILITIES=$(jq -r '.capabilities // "h265,adaptive"' < ${configfile})
QUALITY=$(jq -r '.quality // "40"' < ${configfile})
playlist=$(wget -q -O- "https://sledovanitv.cz/api/playlist?PHPSESSID=${SLEDOVANITVID}&quality=${QUALITY}&capabilities=${CAPABILITIES}")

# Nacti z nej nazvvy skupin
eval $(echo $playlist |  jq -r '.groups  | to_entries[] | "SLEDOVANITVGRP\(.key)=\"\(.value)\"\n"')

# Ma se zahrnout i programy chranene pinem?
pin4parents=$(jq -r ".pin" < ${configfile})

if [ ${pin4parents} != null ]; then
  lockedpin="pin"
fi

# Vytvarim novy playlist
echo "#EXTM3U"
echo $playlist | jq -r  '.channels | to_entries[] | select ((.value.locked=="none" or .value.locked=="'${lockedpin}'") and .value.type=="tv") | "#EXTINF:-1 tvg-chno=\"\(.key+1)\" tvg-id=\"\(.value.id)\" epg-id=\"\(.value.id)\" tvg-name=\"\(.value.name)\" tvg-logo=\"\(.value.logoUrl)\"  group-title=\"${SLEDOVANITVGRP\(.value.group)}\",\(.value.name)\npipe://'$(dirname $(realpath $0) )'/sledovanitv-playback.sh \"\(.value.url | sub("\\.\\?PHPSESSID=[0-9a-z]+";"?PHPSESSID=%PHPSESSID%") )\" \"\(.value.name)\""' > ${FILETMP}
sed -i -E 's/["#&()]/\\\\\0/g' ${FILETMP}

# Vypis playlist a nahrad v nem nazvy skupin
while read; do eval echo -e ${REPLY}; done < ${FILETMP}

rm ${FILETMP}
