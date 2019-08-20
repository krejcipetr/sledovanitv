#!  /bin/bash

dir=$(dirname $0)

read -p "SledovaniTV.cz email:" weblogin
read -s -p "Heslo:" webpasswd
echo
regaddress=https://sledovanitv.cz/api/create-pairing?username=${weblogin}\&password=${webpasswd}\&type=xbmc\&product=$(hostname)\&serial=00:00:00:00:00:00
regstring=$(wget -q -O - --no-check-certificate ${regaddress})
echo "${regstring}" | grep -q -E "\"status\":1"
if [ $? -gt 0 ]; then
    echo ${regstring} >> /dev/stderr
    exit 3
fi

id=$(echo "${regstring}" | jq -r ".deviceId")
password=$(echo "${regstring}" | jq -r ".password")

tmp=$(mktemp)
cat ${dir}/config.json | jq '.device += {"id":"'${id}'","password":"'${password}'"}' > ${tmp}
cat ${tmp} > ${dir}/config.json
rm ${tmp}