FROM linuxserver/tvheadend:latest
LABEL authors="krejci"

# 1. Odskriptuje/povolí řádek s community repozitářem v konfiguraci apk
RUN sed -i 's/^#\(.*community\)/\1/' /etc/apk/repositories \
    && apk update \
    && apk add --no-cache moreutils curl
RUN apk add --no-cache python3 py3-pip
RUN apk add --no-cache libva libva-utils intel-media-driver
RUN apk add --no-cache ffmpeg
RUN pip install --break-system-packages streamlink
RUN /usr/bin/test -d /usr/local/sledovanitv ] || mkdir /usr/local/sledovanitv
RUN /usr/bin/test -d /recordings ] || mkdir /recordings
RUN rm -f /usr/bin/tv_grab_*
COPY sledovanitv* /usr/local/sledovanitv/
COPY config/config /config
COPY config/config.json /config/sledovanitv-config.json
COPY config/tv_grab_sledovanitv /usr/bin/tv_grab_sledovanitv

RUN /usr/bin/test -d /config/sledovanitv ] || mkdir /config/sledovanitv
RUN mkdir -p /etc/services.d/sledovanitv-proxy
RUN echo -e '#!/usr/bin/with-contenv sh\nexec s6-setuidgid abc python3 /usr/local/sledovanitv/sledovanitv-ipvproxy.py' > /etc/services.d/sledovanitv-proxy/run
RUN chmod +x /etc/services.d/sledovanitv-proxy/run
RUN chown -R abc:abc /config /recordings
RUN chmod +x /usr/bin/tv_grab_sledovanitv

VOLUME ["/config","/recordings"]
