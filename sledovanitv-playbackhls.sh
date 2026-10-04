#!  /bin/sh

ffmpeg -nostats -loglevel error \
  -fflags +genpts+igndts \
  -i "$(cat "${1}")" \
  -avoid_negative_ts make_zero -muxdelay 0 -muxpreload 0 \
  -map 0:p:0 \
  -c copy \
  -f mpegts \
  -metadata service_provider=SledovaniTV -metadata service_name="${2}" \
  pipe:1
