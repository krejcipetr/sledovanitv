FROM linuxserver/tvheadend:version-fcd987f0
LABEL authors="krejci"

# 1. Odskriptuje/povolí řádek s community repozitářem v konfiguraci apk
RUN sed -i 's/^#\(.*community\)/\1/' /etc/apk/repositories \
    && apk update \
    && apk upgrade \
    && apk add --no-cache moreutils python3 py3-pip ffmpeg libva libva-utils intel-media-driver ffmpeg \
    && pip install --break-system-packages streamlink \
    && apk cache clean
RUN /usr/bin/test -d /usr/local/sledovanitv ] || mkdir /usr/local/sledovanitv
RUN /usr/bin/test -d /recordings ] || mkdir /recordings
COPY sledovanitv* /usr/local/sledovanitv/
COPY config/config /config
COPY config/config.json /config/sledovanitv_config.json
COPY config/tv_grab_sledovanitv /usr/bin/tv_grab_sledovanitv

RUN /usr/bin/test -d /config/sledovanitv ] || mkdir /config/sledovanitv
RUN chown -R abc:abc /config /recordings
RUN chmod +x /usr/bin/tv_grab_sledovanitv

VOLUME ["/config","/recordings"]
