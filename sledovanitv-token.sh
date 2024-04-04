#!  /bin/bash

configfile=$(dirname $0)/config.json

cachedir=$(jq -r '.tempdir // "'${HOME}'/.cache"' < ${configfile})
tokenfile=${cachedir}/sledovanitv_token

if [ -s ${tokenfile} ]; then

	file_time=$(( $(stat -t ${tokenfile} | cut -d" " -f 13) ))
	current_time=$(date +%s)

	# Stari max 1hod
	stari=$(( current_time - 60 * 60 * 24 ))

	if [ ${file_time} -gt ${stari} ]; then
		SLEDOVANITVID=$(cat ${tokenfile})
	fi
fi

if [ -z "${SLEDOVANITVID}" ]; then
	conf_deviceid=$(jq -r ".device.id" < ${configfile})
	conf_devauthid=$(jq -r ".device.password" < ${configfile})
	
	if [ -z "${conf_deviceid}" -o -z "${conf_devauthid}" ]; then
		echo "Neexistuje soubor s konfiguraci zarizeni. Pouzijte sledovanitv-register.sh" >> /dev/stderr
		return
	fi

	#SLEDOVANITVID=$(wget -qO - "http://sledovanitv.cz/api/device-login?deviceId=${conf_deviceid}&password=${conf_devauthid}&version=3.2.004&lang=cs&unit=default" | jq -r ".PHPSESSID" )
	SLEDOVANITVID=$(wget -qO - "http://sledovanitv.cz/api/device-login?deviceId=${conf_deviceid}&password=${conf_devauthid}&unit=default" | jq -r ".PHPSESSID" )

	if [ -z "${SLEDOVANITVID}" -o "${SLEDOVANITVID}" == "null" ]; then
		echo "Nepodarilo se prihlasit" ${SLEDOVANITVID} >> /dev/stderr
		return 
	fi
	[ -f ${tokenfile} ] && rm ${tokenfile}
	echo -n "${SLEDOVANITVID}" > ${tokenfile}

        pin4parents=$(jq -r ".pin" < ${configfile})

	if [ ${pin4parents} != null ]; then
		wget -qO /dev/null "https://sledovanitv.cz/api/pin-unlock?pin=${pin4parents}&whitelogo=1&PHPSESSID=${SLEDOVANITVID}"
	fi
fi
