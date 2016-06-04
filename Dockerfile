FROM ruby:2.3.1-alpine
MAINTAINER Ryan Schlesinger <ryan@outstand.com>

RUN addgroup metaractor && \
    adduser -S -G metaractor metaractor

ENV GOSU_VERSION 1.9
ENV DUMB_INIT_VERSION 1.0.3

RUN apk add --no-cache ca-certificates gnupg && \
    mkdir -p /tmp/build && \
    cd /tmp/build && \
    gpg --keyserver pool.sks-keyservers.net --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 && \
    curl -o gosu -SL "https://github.com/tianon/gosu/releases/download/${GOSU_VERSION}/gosu-amd64" && \
    curl -o gosu.asc -SL "https://github.com/tianon/gosu/releases/download/${GOSU_VERSION}/gosu-amd64.asc" && \
    gpg --verify gosu.asc && \
    chmod +x gosu && \
    cp gosu /bin/gosu && \
    wget https://github.com/Yelp/dumb-init/releases/download/v${DUMB_INIT_VERSION}/dumb-init_${DUMB_INIT_VERSION}_amd64 && \
    wget https://github.com/Yelp/dumb-init/releases/download/v${DUMB_INIT_VERSION}/sha256sums && \
    grep dumb-init_${DUMB_INIT_VERSION}_amd64$ sha256sums | sha256sum -c && \
    chmod +x dumb-init_${DUMB_INIT_VERSION}_amd64 && \
    cp dumb-init_${DUMB_INIT_VERSION}_amd64 /bin/dumb-init && \
    cd /tmp && \
    rm -rf /tmp/build && \
    apk del gnupg && \
    rm -rf /root/.gnupg

RUN apk add --no-cache \
    build-base \
    git \
    openssh

COPY Gemfile metaractor.gemspec /metaractor/
COPY lib/metaractor/version.rb /metaractor/lib/metaractor/
RUN cd /metaractor \
    && bundle install \
    && git config --global push.default simple
COPY . /metaractor/
RUN chown -R metaractor:metaractor /metaractor

WORKDIR /metaractor

COPY docker-entrypoint.sh /docker-entrypoint.sh

ENV DUMB_INIT_SETSID 0
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["rspec", "spec"]
