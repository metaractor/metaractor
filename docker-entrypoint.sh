#!/bin/sh
set -e

if [ "$(which "$1")" = '' ]; then
  if [ "$(ls -A /usr/local/bundle/bin)" = '' ]; then
    echo 'command not in path and bundler not initialized'
    echo 'running bundle install'
    su-exec metaractor bundle install
  fi
fi

if [ "$1" = 'bundle' ]; then
  set -- su-exec metaractor "$@"
elif ls /usr/local/bundle/bin | grep -q "\b$1\b"; then
  set -- su-exec metaractor bundle exec "$@"

  su-exec metaractor ash -c 'bundle check || bundle install'
fi

exec "$@"
