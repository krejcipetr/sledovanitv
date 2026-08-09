#!  /bin/bash 

source "$(dirname "${0}")/sledovanitv-token.sh"

if [ ! -d "${cachedir}"/sledovanitv  ]; then
	mkdir -p "${cachedir}"/sledovanitv
fi

FILETMP=${cachedir}/sledovanitv/playlist

# Prevzeti pripadnych parametru z prikazove radky
if [ -n "${1}" ]; then
  CAPABILITIES="${1}"
else
  CAPABILITIES=$(jq -r '.capabilities // "h264"' "${configfile}")
fi
if [ -n "${2}" ]; then
  QUALITY="${2}"
else
  QUALITY=$(jq -r '.quality // "40"' "${configfile}")
fi
if [ -z "${QUALITY}" ] || [ "${QUALITY}" = "null" ]; then
  QUALITY=40
fi

if  grep -q -E 'h265|adaptive' <<< ${CAPABILITIES}; then
  format=m3u8
else
  format=vlc
fi
playback='pipe:///usr/local/sledovanitv/sledovanitv-playback.sh '${cachedir}'/sledovanitv/\(.value.id) \"\(.value.name)\"'

# *************************************
# FETCH PLAYLIST
curl -o "${FILETMP}original" -s -A "VLC/3.0.18 LibVLC/3.0.18" "https://sledovanitv.cz/api/playlist?PHPSESSID=${SLEDOVANITVID}&format=${format}&quality=${QUALITY}&capabilities=${CAPABILITIES}"

# *************************************
# CHANNELS
eval "$( jq -r '(.channels // []) | to_entries[] | select ( .value.quality ) | "QUALITY\(.value.id | gsub("[^A-Za-z0-9_]"; "_"))=\"\(.value.quality)\"\n"' "${configfile}" )"
eval "$( jq -r '(.channels // []) | to_entries[] | select ( .value.capabilities) | "CAPABILITIES\(.value.id | gsub("[^A-Za-z0-9_]"; "_"))=\"\(.value.capabilities)\"\n"' "${configfile}" )"

# *************************************
# GROUPS
eval "$( jq -r '.groups  | to_entries[] | "SLEDOVANITVGRP\(.key)=\"\(.value)\"\n"' "${FILETMP}original" )"

# ****************************************
# PIN
pin4parents=$(jq -r ".pin" < "${configfile}")

if [ "${pin4parents}" != null ]; then
  lockedpin="pin"
fi

# ****************************************
# stream URL
for def in $( jq -r  '.channels | to_entries[] | select ((.value.locked=="none" or .value.locked=="'"${lockedpin}"'") and .value.type=="tv") | "\(.value.id)#\(.value.url)"' "${FILETMP}original" ); do
  programname=$(echo "${def}" | cut -d# -f1)
  filename="${cachedir}/sledovanitv/${programname}"
  safe_programname="${programname//[^A-Za-z0-9_]/_}"

  quality_var="QUALITY${safe_programname}"
  capabilities_var="CAPABILITIES${safe_programname}"
  CHQUALITY="${!quality_var}"
  CHCAPABILITIES="${!capabilities_var}"

  if [ -n "${CHQUALITY}" ] || [ -n "${CHCAPABILITIES}" ]; then
      url="https://sledovanitv.cz/vlc/api-channel/${programname}.m3u8?quality=${CHQUALITY:-${QUALITY}}&capabilities=${CHCAPABILITIES:-${CAPABILITIES}}&PHPSESSID=${SLEDOVANITVID}"
  else
      url=$(echo "${def}" | cut -d'#' -f2)
  fi
  echo "${url}" > "${filename}"
done

# ****************************************
# PLAYLIST
jq -r  '.channels | to_entries[] | select ((.value.locked=="none" or .value.locked=="'${lockedpin}'") and .value.type=="tv") | "#EXTINF:-1 tvg-chno=\"\(.key+1)\" tvg-id=\"\(.value.id)\" epg-id=\"\(.value.id)\" tvg-name=\"\(.value.name)\" tvg-logo=\"\(.value.logoUrl)\"  group-title=\"${SLEDOVANITVGRP\(.value.group)}\",\(.value.name)\n'"${playback}"'"' "${FILETMP}original" > "${FILETMP}_tmp"
sed -i -E 's/["#&()]/\\\\\0/g' "${FILETMP}_tmp"

# Vypis playlist a nahrad v nem nazvy skupin
echo "#EXTM3U" > ${FILETMP}
while read; do eval echo -e "${REPLY}"; done < "${FILETMP}_tmp" >>"${FILETMP}"
rm "${FILETMP}_tmp"

# Vypis to na STDOUT
cat "${FILETMP}"
