#!/bin/sh
mkdir -p $ZIP_DESTINATION_PATH
for url in $ZIP_URLS; do 
  foldername=$(basename "$url" .zip)
  if [ -z "${DONT_APPEND_ZIP_NAME}" ]; then
    foldername=""
  else
  wget $url -O /tmp/archive.zip && unzip /tmp/archive.zip -o -d $ZIP_DESTINATION_PATH/$foldername; 
done