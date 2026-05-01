# syntax=docker/dockerfile:1

FROM alpine:3.23@sha256:5b10f432ef3da1b8d4c7eb6c487f2f5a8f096bc91145e68878dd4a5019afde11 AS base

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

USER anope

WORKDIR /anope/

CMD ["/anope/bin/anope", "-n"]
