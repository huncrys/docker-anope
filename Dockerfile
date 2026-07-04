# syntax=docker/dockerfile:1

FROM alpine:3.24@sha256:28bd5fe8b56d1bd048e5babf5b10710ebe0bae67db86916198a6eec434943f8b AS base

FROM base AS builder

# renovate: datasource=github-tags depName=anope/anope
ARG ANOPE_VERSION=2.1.24
ARG EXTRASMODULES="regex_pcre2 ssl_gnutls sqlite mysql"

RUN apk add --no-cache gcc g++ ninja git cmake gettext-dev gnutls-dev sqlite-dev mariadb-dev pcre2-dev
RUN adduser -u 10000 -h /anope/ -D -S anope

ADD https://github.com/anope/anope.git#${ANOPE_VERSION} /src

WORKDIR /src

# Add and overwrite modules
ARG EXTRASMODULES
RUN <<EOF
  for module in $EXTRASMODULES; do
    ln -s /src/modules/extra/${module}.cpp /src/modules/
  done
EOF

WORKDIR /src/build

RUN cmake -DINSTDIR=/anope/ -DDEFUMASK=077 -DCMAKE_BUILD_TYPE=RELEASE -GNinja .. && ninja install

FROM base

RUN apk add --no-cache libgcc libstdc++ libintl gnutls gnutls-utils sqlite-libs mariadb-client mariadb-connector-c pcre2 msmtp && \
    # Create a user to run anope later
    adduser -u 10000 -h /anope/ -D -S anope

COPY --from=builder --chown=anope:anope /anope/ /anope/

# mariadb-connector-c >= 3.4 defaults to requiring TLS even when the server
# has none configured, and the mysql module exposes no SSL option to work
# around it, so restore the previous plaintext-by-default behaviour.
ENV MARIADB_TLS_DISABLE_PEER_VERIFICATION=1

USER anope

WORKDIR /anope/

CMD ["/anope/bin/anope", "-n"]
