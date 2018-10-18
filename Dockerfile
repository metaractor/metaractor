FROM ruby:2.5.1-alpine
MAINTAINER Ryan Schlesinger <ryan@outstand.com>

RUN addgroup -g 1000 -S metaractor && \
    adduser -u 1000 -S -s /bin/ash -G metaractor metaractor && \
    apk add --no-cache \
      ca-certificates \
      tini \
      su-exec \
      build-base \
      git \
      openssh

WORKDIR /metaractor
RUN chown -R metaractor:metaractor /metaractor
USER metaractor

COPY --chown=metaractor:metaractor Gemfile metaractor.gemspec /metaractor/
COPY --chown=metaractor:metaractor lib/metaractor/version.rb /metaractor/lib/metaractor/
RUN git config --global push.default simple
COPY --chown=metaractor:metaractor . /metaractor/

USER root
COPY docker-entrypoint.sh /docker-entrypoint.sh

ENTRYPOINT ["/sbin/tini", "-g", "--", "/docker-entrypoint.sh"]
CMD ["rspec", "spec"]
