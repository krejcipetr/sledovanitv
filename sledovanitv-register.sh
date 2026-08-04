#!  /bin/bash 

read -p "SledovaniTV.cz email:" weblogin
read -s -p "Heslo:" webpasswd
echo

mac=$( ( find /sys/class/net -mindepth 1 -maxdepth 1 ! -name lo -exec cat {}/address \; )  | head -n 1 )
regaddress='https://sledovanitv.cz/api/create-pairing?username='"${weblogin}"'&password='"${webpasswd}"'&type=xbmc&product='$(hostname)'&serial=${mac}'
regstring=$(curl -s -A "VLC/3.0.18 LibVLC/3.0.18" "${regaddress}")
if grep -q -E '"status":1' <<< "${regstring}"; then
    echo "${regstring}" > /dev/stderr
    exit 3
fi

id=$(echo "${regstring}" | jq -r ".deviceId")
password=$(echo "${regstring}" | jq -r ".password")

# Vytvoreni json config souboru
if [ ! -s "${HOME}/sledovanitv_config.json" ]; then
    echo "{}" > "${HOME}/sledovanitv_config.json"
fi
jq '.device += {"id":"'"${id}"'","password":"'"${password}"'","serial":"'"${mac}"'"}' "${HOME}"/sledovanitv_config.json | sponge "${HOME}"/sledovanitv_config.json

# Smazani cache
cachedir=$(jq -r '.tempdir//'"${HOME}"'/.cache' < "${HOME}/sledovanitv_config.json")
rm -rf "${cachedir}/sledovanitv/"*
rm -f "${cachedir}"/sledovanitv_token




