#!  /bin/bash 

source $(dirname $0)/sledovanitv-token.sh

if [ -s ${autoconfigfile} ]; then

	if [ ${autoconfigfile} -nt ${configfile} ]; then
		# soubor je stale aktualni, tak vratim jeho obsah
		cat ${autoconfigfile}
		exit 
	fi
fi

# soubor neexistuje, nebo uz neni aktualni, tak ho pregeneruji

# je v config.json seznam aktivnich kanalu? Pokud ne, tak ho naplnim podle EPG
channels="{}"
if [ "null" == "$(jq -r '.channels[0]' ${configfile} )" ]; then
	for id in $(wget -q -O- "http://sledovanitv.cz/api/epg?PHPSESSID=${PHPSESSID}&detail=1&duration=1439"  | jq '.channels | to_entries[] | .key ' | sort ); do
		channels=$(echo $channels |  jq '.channels += [{"id":'${id}',"label":'${id}',"disable":"true"}]')
	done
	
	tmp=$(mktemp)
	cat $configfile | jq ". += ${channels}" > ${tmp}
	cat ${tmp} >  ${configfile}
	rm ${tmp}
fi

# Vytvarim novy autoconfigfile
echo "#EXTM3U" > ${autoconfigfile}

for channel in $(  jq -r '.channels[] | select (.disable!="true") | [.id,.label] |  @csv' ${configfile} ) ; do
	id=$(echo $channel | cut -f1 -d,)
	label=$(echo $channel | cut -f2 -d,)
	
	echo '#EXTINF:0 epg-id='${id}','$(echo ${label} | sed -e 's/"//g') >> ${autoconfigfile}
	echo 'pipe://'$(realpath $(dirname $0))'/sledovanitv-playback.sh '${id} >> ${autoconfigfile}
done

cat ${autoconfigfile}


#
