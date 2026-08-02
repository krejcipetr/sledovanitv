#!  /bin/bash

# Pouzite parametry jsou nasledujici:
ffmpeg -nostats -loglevel 0 \
  -protocol_whitelist "https,http,tls,file,tcp,crypto" \
  -reconnect 1 -reconnect_at_eof 1 -reconnect_streamed 1 -reconnect_delay_max 5 \
  -i "$(cat "${1}")" \
  -c copy -map 0  -f mpegts \
  -metadata service_provider=SledovaniTV -metadata service_name="${2}" \
   pipe:1

#streamlink "$(cat "${1}")" best -O -l none | ffmpeg -nostats -loglevel 0 -i - -c copy -f mpegts -metadata service_provider=SledovaniTV -metadata service_name="${2}" pipe:1
