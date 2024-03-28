#!/bin/sh
mkdir -p $ZIP_DESTINATION_PATH
for url in $ZIP_URLS; do 
  foldername=$(basename "$url" .zip)
  wget $url -O /tmp/archive.zip && unzip /tmp/archive.zip -o -d $ZIP_DESTINATION_PATH/$foldername; 
done