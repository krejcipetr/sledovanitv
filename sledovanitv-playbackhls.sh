#!  /bin/sh

# vezmi ze souboru druhy radek a to jsou titulku
titulky=$(sed -n '2p' "${1}")
#if [ -n "${titulky}" ]; then
#  ffmpeg  -nostats \
#  -loglevel error \
#  -protocol_whitelist "pipe,https,http,tls,file,tcp,crypto,hls" \
#  -i "${titulky}" \
#  -map 0:s? \
#  /recordings/tv_subtitles.srt &
#fi

ffmpeg -nostats \
  -loglevel error \
  -protocol_whitelist "pipe,https,http,tls,file,tcp,crypto,hls" \
  -i http://localhost:9393/"$(basename ${1})" \
  -map 0:v \
  -map 0:a \
  -c:v copy \
  -c:a copy  \
  -f mpegts \
  -metadata service_provider=SledovaniTV \
  -metadata service_name="${2}" \
  pipe:1