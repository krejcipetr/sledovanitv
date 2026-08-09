#!  /bin/sh

# Pokud je v souboru m3u8, tak pred prikaz dej curl na streamlink
if grep -q m3u8 "${1}"; then
    "$(dirname $0)"/sledovanitv-playbackhls.sh "${1}" "${2}"
    exit 0
fi


ffmpeg -nostats -loglevel panic \
  -protocol_whitelist "https,http,tls,file,tcp,crypto,hls" \
  -reconnect 1 -reconnect_at_eof 1 -reconnect_streamed 1 -reconnect_delay_max 5 \
  -analyzeduration 6000000 \
  -probesize 60000000 \
  -user_agent "VLC/3.0.18 LibVLC/3.0.18" \
  -i "$(cat "${1}")" \
  -map 0 \
  -c copy \
  -f mpegts \
  -metadata service_provider=SledovaniTV -metadata service_name="${2}" \
  pipe:1


#curl -sL -A "VLC/3.0.18 LibVLC/3.0.18" "$(cat "${1}")"