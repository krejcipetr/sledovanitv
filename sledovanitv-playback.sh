#!  /bin/bash

# Pouzite parametry jsou nasledujici:

ffmpeg -nostats -loglevel 0 -protocol_whitelist "https,http,tls,file,tcp" -i $(cat ${1}) -c copy -map 0  -f mpegts -metadata service_provider=SledovaniTV -metadata service_name="${2}"  pipe:1
