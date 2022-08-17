FROM outstand/fixuid as fixuid

FROM ruby:2.7.6-alpine
LABEL maintainer="Ryan Schlesinger <ryan@outstand.com>"

RUN set -eux; \
      \
      apk add --no-cache \
        bash

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
ENV DEBIAN_FRONTEND=noninteractive

RUN set -eux; \
      \
      addgroup -g 1000 -S metaractor; \
      adduser -u 1000 -S -s /bin/ash -G metaractor metaractor; \
      \
      apk add --no-cache \
        ca-certificates \
        tini \
        su-exec \
        build-base \
        git \
        openssh

COPY --from=fixuid /usr/local/bin/fixuid /usr/local/bin/fixuid
RUN set -eux; \
      \
      chmod 4755 /usr/local/bin/fixuid; \
      USER=metaractor; \
      GROUP=metaractor; \
      mkdir -p /etc/fixuid; \
      printf "user: $USER\ngroup: $GROUP\n" > /etc/fixuid/config.yml

ENV BUNDLER_VERSION 2.3.20
RUN set -eux; \
      \
      gem install bundler -v ${BUNDLER_VERSION} -i /usr/local/lib/ruby/gems/$(ls /usr/local/lib/ruby/gems) --force

WORKDIR /metaractor
RUN set -eux; \
      \
      chown -R metaractor:metaractor /metaractor

USER metaractor

COPY --chown=metaractor:metaractor Gemfile metaractor.gemspec /metaractor/
COPY --chown=metaractor:metaractor lib/metaractor/version.rb /metaractor/lib/metaractor/
RUN set -eux; \
      \
      git config --global push.default simple
COPY --chown=metaractor:metaractor . /metaractor/

USER root
COPY docker-entrypoint.sh /docker-entrypoint.sh

ENTRYPOINT ["/sbin/tini", "-g", "--", "/docker-entrypoint.sh"]
CMD ["rspec", "spec"]
