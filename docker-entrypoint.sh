#!/bin/dumb-init /bin/sh
set -e

if [ "$1" = 'rspec' ]; then
  set -- bundle exec "$@"
fi

if [ "$1" = 'bundle' ]; then
  set -- gosu metaractor "$@"
fi

exec "$@"
