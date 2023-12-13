FROM alpine:3.19.0

ARG VERSION=2.1.0
ARG RUN_DEPENDENCIES=pcre msmtp
ARG BUILD_DEPENDENCIES=pcre-dev

RUN apk add --no-cache --virtual .build-utils gcc g++ ninja git cmake gnutls-dev sqlite-dev mariadb-dev $BUILD_DEPENDENCIES && \
    apk add --no-cache --virtual .dependencies libgcc libstdc++ gnutls gnutls-utils sqlite-libs mariadb-client mariadb-connector-c $RUN_DEPENDENCIES && \
    # Create a user to run anope later
    adduser -u 10000 -h /anope/ -D -S anope && \
    mkdir -p /src && \
    cd /src && \
    # Clone the requested version
    git clone --depth 1 https://github.com/anope/anope.git anope -b $VERSION && \
    cd /src/anope && \
    # Add and overwrite modules
    ln -s /src/anope/modules/extra/m_mysql.cpp modules && \
    ln -s /src/anope/modules/extra/m_regex_pcre.cpp modules && \
    ln -s /src/anope/modules/extra/m_sql_authentication.cpp modules && \
    ln -s /src/anope/modules/extra/m_sql_log.cpp modules && \
    ln -s /src/anope/modules/extra/m_sql_oper.cpp modules && \
    ln -s /src/anope/modules/extra/m_sqlite.cpp modules && \
    ln -s /src/anope/modules/extra/m_ssl_gnutls.cpp modules && \
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
