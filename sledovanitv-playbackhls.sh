#!  /bin/sh -x

# vezmi ze souboru druhy radek a to jsou titulku
titulky=$(sed -n '2p' "${1}")

ffmpeg -nostats \
  -loglevel error \
  -protocol_whitelist "pipe,https,http,tls,file,tcp,crypto,hls" \
  -i http://localhost:9393/"$(basename ${1})" \
  -map 0 \
  -c:v copy -c:a copy -c:s text \
  -f mpegts \
  -metadata service_provider=SledovaniTV \
  -metadata service_name="${2}" \
  pipe:1
