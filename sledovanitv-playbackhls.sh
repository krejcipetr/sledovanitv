#!  /bin/sh

curl -s -A "VLC/3.0.18 LibVLC/3.0.18" http://localhost:9393/"$(basename ${1})"  |  \
ffmpeg -nostats -loglevel panic \
  -protocol_whitelist "pipe" \
  -analyzeduration 6000000 \
  -probesize 60000000 \
  -i pipe:0 \
  -map 0 \
  -c copy \
  -f mpegts \
  -metadata service_provider=SledovaniTV -metadata service_name="${2}" \
  pipe:1
