#!  /bin/bash

# Pouzite parametry jsou nasledujici:
source `dirname $0`/sledovanitv-token.sh

ffmpeg -nostats -loglevel 0 -protocol_whitelist "https,http,tls,file,tcp" -i "$(echo ${1} | sed -E 's/%PHPSESSID%/'${SLEDOVANITVID}'/g')" -c copy -map 0  -f mpegts -metadata service_provider=SledovaniTV -metadata service_name=${2}  pipe:1
