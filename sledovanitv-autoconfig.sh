#!  /bin/bash 

source $(dirname $0)/sledovanitv-token.sh

FILETMP=${cachedir}/sledovanitv/playlist

if [ -s ${FILETMP} ]; then
        file_time=$(( $(stat -t ${FILETMP} | cut -d" " -f 13) ))
        current_time=$(date +%s)

        # Stari max 8h
        stari=$(( current_time - 60 * 60 * 8 ))

        if [ ${file_time} -gt ${stari} ]; then
                cat  ${FILETMP}
		exit
        fi
fi

echo "#EXTM3U" > ${FILETMP}

if [ ! -d ${cachedir}/sledovanitv  ]; then
	mkdir -p ${cachedir}/sledovanitv
fi

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

# ulozeni definic
for def in $(echo $playlist | jq -r  '.channels | to_entries[] | select ((.value.locked=="none" or .value.locked=="'${lockedpin}'") and .value.type=="tv") | "\(.value.id)#\(.value.url)"'); do
	filename=${cachedir}/sledovanitv/$(echo ${def} | cut -d# -f1)

	url=$(echo ${def} | cut -d'#' -f2)
	echo ${url} > ${filename}
done

# Vytvarim novy playlis
echo $playlist | jq -r  '.channels | to_entries[] | select ((.value.locked=="none" or .value.locked=="'${lockedpin}'") and .value.type=="tv") | "#EXTINF:-1 tvg-chno=\"\(.key+1)\" tvg-id=\"\(.value.id)\" epg-id=\"\(.value.id)\" tvg-name=\"\(.value.name)\" tvg-logo=\"\(.value.logoUrl)\"  group-title=\"${SLEDOVANITVGRP\(.value.group)}\",\(.value.name)\npipe://'$(dirname $(realpath $0) )'/sledovanitv-playback.sh \"'${cachedir}/sledovanitv/'\(.value.id)\" \"\(.value.name)\""' > ${FILETMP}_tmp

sed -i -E 's/["#&()]/\\\\\0/g' ${FILETMP}_tmp

# Vypis playlist a nahrad v nem nazvy skupin
while read; do eval echo -e ${REPLY}; done <${FILETMP}_tmp >>${FILETMP}

cat ${FILETMP}

rm ${FILETMP}
