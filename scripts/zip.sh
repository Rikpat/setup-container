#!/bin/sh
for url in $ZIP_URLS; do 
  foldername=""
  if [ -z "${DONT_APPEND_ZIP_NAME}" ]; then
    foldername=$(basename "$url" .zip)
  fi
  mkdir -p $ZIP_DESTINATION_PATH/$foldername
  wget $url -O /tmp/archive.zip && unzip /tmp/archive.zip -o -d $ZIP_DESTINATION_PATH/$foldername; 
done
