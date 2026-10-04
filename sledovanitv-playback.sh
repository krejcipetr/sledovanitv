#!  /bin/sh

ffmpeg -nostats -loglevel panic \
  -protocol_whitelist "https,http,tls,file,tcp,crypto,hls" \
  -fflags +genpts+igndts \
  -user_agent "VLC/3.0.18 LibVLC/3.0.18" \
  -i "$(cat "${1}")" \
  -avoid_negative_ts make_zero -muxdelay 0 -muxpreload 0 \
  -map 0:p:0 \
  -c copy \
  -f mpegts \
  -metadata service_provider=SledovaniTV -metadata service_name="${2}" \
  pipe:1