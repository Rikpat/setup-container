#!/bin/sh
set -e

PROCESSED=false
WORKDIR=/workdir
TARGETDIR=/target

for path in $(find -L /workdir/data -type f); do
  relativepath=${path#"$WORKDIR"}
  echo "Processing $relativepath ..."
  mkdir -p "$TARGETDIR/$(dirname $relativepath)" # create directory structure if not exists
  envsubst < "$path" > "$TARGETDIR/$relativepath"
  PROCESSED=true
done

if [ ! $PROCESSED = true ]; then
  echo 'No files processed'
  exit 1
fi