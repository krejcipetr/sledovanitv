FROM linuxserver/tvheadend:version-b162cce2
LABEL authors="krejci"

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
