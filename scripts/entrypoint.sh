#!/bin/sh

# if root, change to user specified in PUID env variable
UID=$(id -u)
if [ $UID -eq 0 ]; then
  addgroup -S -g $PGID workgroup
  adduser -S -u $PUID -G workgroup workuser
  su workuser -s /bin/sh -c "$@"
else
  /bin/sh -c "$@"
fi