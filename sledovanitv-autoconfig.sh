#!  /bin/bash 

source "$(dirname "${0}")/sledovanitv-token.sh"

if [ ! -d "${cachedir}"/sledovanitv  ]; then
	mkdir -p "${cachedir}"/sledovanitv
fi

FILETMP=${cachedir}/sledovanitv/playlist

# Nacti playlist
if [ -n "${1}" ]; then
  CAPABILITIES="${1}"
else
  CAPABILITIES=$(jq -r '.capabilities // "h265"' < "${configfile}")
fi
QUALITY=$(jq -r '.quality // "40"' < "${configfile}")

if  grep -q -E 'h265|adaptive' <<< "${CAPABILITIES}"; then
  playback='http://127.0.0.1:9393/\(.value.id)'
  format=m3u8
else
  playback='pipe:///usr/local/sledovanitv/sledovanitv-playback.sh '${cachedir}'/sledovanitv/\(.value.id) \"\(.value.name)\"'
  format=vlc
fi


playlist=$(curl -s -A "VLC/3.0.18 LibVLC/3.0.18" "https://sledovanitv.cz/api/playlist?PHPSESSID=${SLEDOVANITVID}&format=${format}&quality=${QUALITY}&capabilities=${CAPABILITIES}")
echo "${playlist}" >  "${FILETMP}original"

# Nacti z nej nazvvy skupin
eval "$(echo "${playlist}" |  jq -r '.groups  | to_entries[] | "SLEDOVANITVGRP\(.key)=\"\(.value)\"\n"')"

# Ma se zahrnout i programy chranene pinem?
pin4parents=$(jq -r ".pin" < "${configfile}")

if [ "${pin4parents}" != null ]; then
  lockedpin="pin"
fi

# ulozeni definic
for def in $(echo "${playlist}" | jq -r  '.channels | to_entries[] | select ((.value.locked=="none" or .value.locked=="'"${lockedpin}"'") and .value.type=="tv") | "\(.value.id)#\(.value.url)"'); do
  programname=$(echo "${def}" | cut -d# -f1)
  filename="${cachedir}/sledovanitv/${programname}"
  url=$(echo "${def}" | cut -d'#' -f2)
  echo "${url}" > "${filename}"
done

# Vytvarim novy playlis


echo "${playlist}" | jq -r  '.channels | to_entries[] | select ((.value.locked=="none" or .value.locked=="'${lockedpin}'") and .value.type=="tv") | "#EXTINF:-1 tvg-chno=\"\(.key+1)\" tvg-id=\"\(.value.id)\" epg-id=\"\(.value.id)\" tvg-name=\"\(.value.name)\" tvg-logo=\"\(.value.logoUrl)\"  group-title=\"${SLEDOVANITVGRP\(.value.group)}\",\(.value.name)\n'"${playback}"'"' > "${FILETMP}_tmp"

sed -i -E 's/["#&()]/\\\\\0/g' "${FILETMP}_tmp"

# Vypis playlist a nahrad v nem nazvy skupin
echo "#EXTM3U" > ${FILETMP}
while read; do eval echo -e "${REPLY}"; done < "${FILETMP}_tmp" >>"${FILETMP}"
rm "${FILETMP}_tmp"

# Vypis to na STDOUT
cat "${FILETMP}"
