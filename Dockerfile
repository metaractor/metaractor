FROM outstand/su-exec:latest as su-exec
FROM outstand/fixuid as fixuid

FROM ruby:2.7.6-bullseye
LABEL maintainer="Ryan Schlesinger <ryan@outstand.com>"

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
ENV DEBIAN_FRONTEND=noninteractive

RUN set -eux; \
      \
      groupadd -g 1000 metaractor && \
      useradd -u 1000 -g metaractor -ms /bin/bash metaractor && \
      \
      apt-get update -y; \
      apt-get install -y \
        ca-certificates \
        curl \
        git \
        build-essential \
        tini \
      ; \
      apt-get clean; \
      rm -f /var/lib/apt/lists/*_*

# install su-exec
COPY --from=su-exec /sbin/su-exec /sbin/su-exec

# install fixuid
COPY --from=fixuid /usr/local/bin/fixuid /usr/local/bin/fixuid
RUN set -eux; \
      \
      chmod 4755 /usr/local/bin/fixuid; \
      USER=metaractor; \
      GROUP=metaractor; \
      mkdir -p /etc/fixuid; \
      printf "user: $USER\ngroup: $GROUP\n" > /etc/fixuid/config.yml

ENV BUNDLER_VERSION 2.3.20
ENV GITHUB_CLI_VERSION 2.14.4
ENV GITHUB_CLI_CHECKSUM b0073fdcc07d1de5a19a1a782c7ad9f593f991da06a809ea39f0b6148869aa96
RUN set -eux; \
      \
      mkdir -p /tmp/build; \
      cd /tmp/build; \
      \
      gem install bundler -v ${BUNDLER_VERSION} -i /usr/local/lib/ruby/gems/$(ls /usr/local/lib/ruby/gems) --force; \
      curl -fsSL https://github.com/cli/cli/releases/download/v${GITHUB_CLI_VERSION}/gh_${GITHUB_CLI_VERSION}_linux_amd64.deb -o gh_${GITHUB_CLI_VERSION}_linux_amd64.deb; \
      echo "${GITHUB_CLI_CHECKSUM}  gh_${GITHUB_CLI_VERSION}_linux_amd64.deb" | sha256sum --check; \
      apt-get update -y; \
      apt-get install -y --no-install-recommends \
        ./gh_${GITHUB_CLI_VERSION}_linux_amd64.deb \
      ; \
      apt-get clean; \
      rm -f /var/lib/apt/lists/*_*; \
      rm -rf /tmp/build

COPY brew-shim /usr/bin/brew

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

ENTRYPOINT ["/usr/bin/tini", "-g", "--", "/docker-entrypoint.sh"]
CMD ["rspec", "spec"]
