#!  /bin/bash

cachefile=${HOME}/.cache/sledovanitv

if [ -s ${cachefile} ]; then

	file_time=$(( $(stat -t ${cachefile} | cut -d" " -f 13) ))
	current_time=$(date +%s)

	stari=$(( current_time - 60 * 60 * 24 * 1 ))

	if [ ${file_time} -gt ${stari} ]; then
		PHPSESSID=$(cat ${cachefile})
	fi
fi

if [ -z "${PHPSESSID}" ]; then
	conf_deviceid=$(jq -r ".device.id" < ${HOME}/sledovanitv/config.json)
	conf_devauthid=$(jq -r ".device.password" < ${HOME}/sledovanitv/config.json)
	
	if [ -z "${conf_deviceid}" -o -z "${conf_devauthid}" ]; then
		echo "Neexistuje soubor s konfiguraci zarizeni. Pouzijte sledovanitv-register.sh" >> /dev/stderr
		exit 1 
	fi

	PHPSESSID=$(wget -qO - "http://sledovanitv.cz/api/device-login?deviceId=${conf_deviceid}&password=${conf_devauthid}&version=3.2.004&lang=cs&unit=default" | jq -r ".PHPSESSID" )

	if [ -z "${PHPSESSID}" ]; then
		echo "Nepodarilo se prihlasit"
		exit 4
	fi
	echo -n "${PHPSESSID}" > ${cachefile}
fi
