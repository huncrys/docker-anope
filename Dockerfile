FROM alpine:3.22

ARG VERSION=2.1.18
ARG RUN_DEPENDENCIES=pcre2 msmtp
ARG BUILD_DEPENDENCIES=pcre2-dev

RUN apk add --no-cache --virtual .build-utils gcc g++ ninja git cmake gettext-dev gnutls-dev sqlite-dev mariadb-dev $BUILD_DEPENDENCIES && \
    apk add --no-cache --virtual .dependencies libgcc libstdc++ libintl gnutls gnutls-utils sqlite-libs mariadb-client mariadb-connector-c $RUN_DEPENDENCIES && \
    # Create a user to run anope later
    adduser -u 10000 -h /anope/ -D -S anope && \
    mkdir -p /src && \
    cd /src && \
    # Clone the requested version
    git clone --depth 1 https://github.com/anope/anope.git anope -b $VERSION && \
    cd /src/anope && \
    # Add and overwrite modules
    ln -s /src/anope/modules/extra/mysql.cpp modules && \
    ln -s /src/anope/modules/extra/regex_pcre2.cpp modules && \
    ln -s /src/anope/modules/extra/sqlite.cpp modules && \
    ln -s /src/anope/modules/extra/ssl_gnutls.cpp modules && \
    ln -s /src/anope/modules/extra/stats modules && \
    mkdir build && \
    cd /src/anope/build && \
    cmake -DINSTDIR=/anope/ -DDEFUMASK=077 -DCMAKE_BUILD_TYPE=RELEASE -GNinja .. && \
    # Run build multi-threaded
    ninja install && \
    # Uninstall all unnecessary tools after build process
    apk del .build-utils && \
    rm -rf /src && \
    # Make sure everything is owned by anope
    chown -R anope /anope/

RUN chown -R anope /anope/conf/

WORKDIR /anope/

USER anope

CMD ["/anope/bin/anope", "-n"]
