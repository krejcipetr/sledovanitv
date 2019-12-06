#!  /bin/bash 

dir=$(dirname $0)

read -p "SledovaniTV.cz email:" weblogin
read -s -p "Heslo:" webpasswd
echo

mac=$( ( find /sys/class/net -mindepth 1 -maxdepth 1 ! -name lo -execdir cat {}/address \; )  | head -n 1 )
regaddress=https://sledovanitv.cz/api/create-pairing?username=${weblogin}\&password=${webpasswd}\&type=xbmc\&product=$(hostname)\&serial=${mac}
regstring=$(wget -q -O - --no-check-certificate ${regaddress})
echo "${regstring}" | grep -q -E "\"status\":1"
if [ $? -gt 0 ]; then
    echo ${regstring} >> /dev/stderr
    exit 3
fi

id=$(echo "${regstring}" | jq -r ".deviceId")
password=$(echo "${regstring}" | jq -r ".password")

tmp=$(mktemp)
if [ ! -s ${dir}/config.json ]; then
    echo "{}" > ${dir}/config.json
fi

cat ${dir}/config.json | jq '.device += {"id":"'${id}'","password":"'${password}'","serial":"'${mac}'"}' > ${tmp}
cat ${tmp} > ${dir}/config.json
rm ${tmp}

rm ${HOME}/.cache/sledovanitv*


