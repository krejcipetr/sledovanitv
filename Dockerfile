FROM linuxserver/tvheadend:version-5abbcda4
LABEL authors="krejci"

RUN [ -d /usr/local/sledovanitv ] || mkdir /usr/local/sledovanitv
RUN [ -d /recordings ] || mkdir /recordings
COPY sledovanitv* /usr/local/sledovanitv/
COPY config/config.json /config/sledovanitv_config.json
COPY config/tv_grab_sledovanitv /usr/bin/tv_grab_sledovanitv

RUN [ -d /config/sledovanitv ] || mkdir /config/sledovanitv

COPY config/config /config
RUN chown -R abc:abc /config /recordings
RUN chmod +x /usr/bin/tv_grab_sledovanitv

VOLUME ["/config","/recordings"]