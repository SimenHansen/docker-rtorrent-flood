FROM alpine:3.10

ARG RTORRENT_VER=0.9.8
ARG LIBTORRENT_VER=0.13.8
ARG MEDIAINFO_VER=19.07
ARG FLOOD_VER=master
ARG BUILD_CORES=4

ENV UID=991 GID=991 \
    FLOOD_SECRET=supersecret \
    WEBROOT=/ \
    RTORRENT_SCGI=0 \
    PKG_CONFIG_PATH=/usr/local/lib/pkgconfig

RUN NB_CORES=${BUILD_CORES-`getconf _NPROCESSORS_CONF`} \
 && apk -U upgrade \
 && apk add -t build-dependencies \
    build-base \
    git \
    libtool \
    automake \
    autoconf \
    wget \
    tar \
    xz \
    zlib-dev \
    cppunit-dev \
    openssl-dev \
    ncurses-dev \
    curl-dev \
    binutils \
    linux-headers \
 && apk add \
    ca-certificates \
    curl \
    ncurses \
    openssl \
    gzip \
    zip \
    zlib \
    s6 \
    su-exec \
    python \
    nodejs \
    nodejs-npm \
    unrar \
    findutils \
 && cd /tmp && mkdir libtorrent rtorrent \
 && cd libtorrent && wget -qO- https://github.com/rakshasa/libtorrent/archive/v${LIBTORRENT_VER}.tar.gz | tar xz --strip 1 \
 && rm src/utils/diffie_hellman.cc \
 && wget -q https://raw.githubusercontent.com/ppentchev/libtorrent/b293276bc5f17f6372146bd605a33340a8162072/src/utils/diffie_hellman.cc -O src/utils/diffie_hellman.cc \
 && cd ../rtorrent && wget -qO- https://github.com/rakshasa/rtorrent/releases/download/v${RTORRENT_VER}/rtorrent-${RTORRENT_VER}.tar.gz | tar xz --strip 1 \
 && cd /tmp \
 && git clone https://github.com/mirror/xmlrpc-c.git \
 && git clone https://github.com/Rudde/mktorrent.git \
 && cd /tmp/mktorrent && make -j ${NB_CORES} && make install \
 && cd /tmp/xmlrpc-c/advanced && ./configure && make -j ${NB_CORES} && make install \
 && cd /tmp/libtorrent && ./autogen.sh && ./configure && make -j ${NB_CORES} && make install \
 && cd /tmp/rtorrent && ./autogen.sh && ./configure --with-xmlrpc-c && make -j ${NB_CORES} && make install \
 && cd /tmp \
 && wget -q http://mediaarea.net/download/binary/mediainfo/${MEDIAINFO_VER}/MediaInfo_CLI_${MEDIAINFO_VER}_GNU_FromSource.tar.gz \
 && wget -q http://mediaarea.net/download/binary/libmediainfo0/${MEDIAINFO_VER}/MediaInfo_DLL_${MEDIAINFO_VER}_GNU_FromSource.tar.gz \
 && tar xzf MediaInfo_DLL_${MEDIAINFO_VER}_GNU_FromSource.tar.gz \
 && tar xzf MediaInfo_CLI_${MEDIAINFO_VER}_GNU_FromSource.tar.gz \
 && cd /tmp/MediaInfo_DLL_GNU_FromSource && ./SO_Compile.sh \
 && cd /tmp/MediaInfo_DLL_GNU_FromSource/ZenLib/Project/GNU/Library && make install \
 && cd /tmp/MediaInfo_DLL_GNU_FromSource/MediaInfoLib/Project/GNU/Library && make install \
 && cd /tmp/MediaInfo_CLI_GNU_FromSource && ./CLI_Compile.sh \
 && cd /tmp/MediaInfo_CLI_GNU_FromSource/MediaInfo/Project/GNU/CLI && make install \
 && strip -s /usr/local/bin/rtorrent \
 && strip -s /usr/local/bin/mktorrent \
 && strip -s /usr/local/bin/mediainfo \
 && ln -sf /usr/local/bin/mediainfo /usr/bin/mediainfo \
 && mkdir /usr/flood && cd /usr/flood && wget -qO- https://github.com/jfurrow/flood/archive/${FLOOD_VER}.tar.gz | tar xz --strip 1 \
 && npm install && npm cache clean --force \
 && apk del build-dependencies \
 && rm -rf /var/cache/apk/* /tmp/*

COPY rootfs /

RUN chmod +x /usr/local/bin/* /etc/s6.d/*/* /etc/s6.d/.s6-svscan/* \
 && cd /usr/flood/ && npm run build

VOLUME /data /flood-db

EXPOSE 49184 49184/udp

LABEL description="BitTorrent client with WebUI front-end" \
      rtorrent="rTorrent BiTorrent client v$RTORRENT_VER" \
      libtorrent="libtorrent v$LIBTORRENT_VER" \
      maintainer="Wonderfall <wonderfall@targaryen.house>"

CMD ["run.sh"]
