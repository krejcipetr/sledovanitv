#!  /bin/sh

curl -s http://localhost:9393/"$(basename ${1})"  |  \
ffmpeg -nostats \
  -loglevel panic \
  -protocol_whitelist "pipe" \
  -fflags +genpts+igndts \
  -i pipe:0 \
  -avoid_negative_ts make_zero \
  -muxdelay 0 \
  -muxpreload 0 \
  -map 0 \
  -c copy \
  -f mpegts \
  -metadata service_provider=SledovaniTV \
  -metadata service_name="${2}" \
  pipe:1
