#!/bin/sh
addgroup -S -g $PGID workgroup
adduser -S -u $PUID -G workgroup workuser
su workuser -s /bin/sh -c "$@"
