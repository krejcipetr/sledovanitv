#!  /bin/sh

curl -s http://localhost:9393/"$(basename ${1})"  |  \
ffmpeg -nostats \
  -loglevel error \
  -protocol_whitelist "pipe" \
  -i pipe:0 \
  -map 0 \
  -c copy \
  -f mpegts \
  -metadata service_provider=SledovaniTV \
  -metadata service_name="${2}" \
  pipe:1
