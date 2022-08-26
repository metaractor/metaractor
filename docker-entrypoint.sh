#!/bin/bash

set -euo pipefail

su-exec ${FIXUID:?Missing FIXUID var}:${FIXGID:?Missing FIXGID var} fixuid

chown_dir() {
  dir=$1
  if [[ -d ${dir} ]] && [[ "$(stat -c %u:%g ${dir})" != "${FIXUID}:${FIXGID}" ]]; then
    echo chown $dir
    chown metaractor:metaractor $dir
  fi
}

chown_dir /usr/local/bundle
chown_dir /home/metaractor/.local/share/gem
chown_dir /home/metaractor/.gem

if [ "$(which "$1")" = '' ]; then
  if [ "$(ls -A /usr/local/bundle/bin)" = '' ]; then
    echo 'command not in path and bundler not initialized'
    echo 'running bundle install'
    su-exec metaractor bundle install
  fi
fi

if [ "$1" = 'bundle' ]; then
  set -- su-exec metaractor "$@"
elif [ "$1" = 'rake' ]; then
  set -- su-exec metaractor bundle exec "$@"

  su-exec metaractor bash -c 'bundle check || bundle install'
elif ls /usr/local/bundle/bin | grep -q "\b$1\b"; then
  set -- su-exec metaractor bundle exec "$@"

  su-exec metaractor bash -c 'bundle check || bundle install'
fi

exec "$@"
