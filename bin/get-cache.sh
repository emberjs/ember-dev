#!/usr/bin/env bash
# Usage: save-cache <DIR1> <DIR2>
#
# Downloads a .tar.gz file from Amazon S3 (using the current project directory)
# and unpacks it in the current directory. This is useful for preserving bundler
# or npm packages for future Travis builds.

file="${PWD##*/}.tar.gz"
url="https://$S3_BUILD_CACHE_BUCKET.s3.amazonaws.com/$file"

if curl --output /dev/null --silent --head --fail "$url"; then
  echo "Downloading cache from: $url"
  curl -O "$url"
  tar -xvzf "$file"
  rm "$file"
else
  echo "No cache found at: $url"
fi
