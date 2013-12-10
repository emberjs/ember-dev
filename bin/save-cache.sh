#!/usr/bin/env bash
# Usage: save-cache <DIR1> <DIR2>
#
# Uploads a .tar.gz file to Amazon S3 (using the current directory name as
# as the base filename).
#
# Depends on AWS credentials being set via env:
# - S3_ACCESS_KEY_ID
# - S3_SECRET_ACCESS_KEY
# - S3_BUILD_CACHE_BUCKET
#
# Outputs the URL of the newly uploaded file.
#
# Based on s3-put: https://github.com/sstephenson/ruby-build/blob/4ed38ba4bceafa3f8908a05b58e6bcf219fbbdc3/script/s3-put

set -e

authorization() {
  local signature="$(string_to_sign | hmac_sha1 | base64)"
  echo "AWS ${S3_ACCESS_KEY_ID?}:${signature}"
}

hmac_sha1() {
  openssl dgst -binary -sha1 -hmac "${S3_SECRET_ACCESS_KEY?}"
}

base64() {
  openssl enc -base64
}

bin_md5() {
  openssl dgst -binary -md5
}

string_to_sign() {
  echo "$http_method"
  echo "$content_md5"
  echo "$content_type"
  echo "$date"
  echo "x-amz-acl:$acl"
  printf "/$bucket/$file"
}

date_string() {
  LC_TIME=C date "+%a, %d %h %Y %T %z"
}

if [ -z "$S3_SECRET_ACCESS_KEY" ] || [ -z "$S3_ACCESS_KEY_ID" ]
then
  echo "Enviroment variables not set. Exiting..."
  exit 0
fi

file="${PWD##*/}.tar.gz"
bucket="$S3_BUILD_CACHE_BUCKET"
content_type="application/x-gzip"

http_method=PUT
acl="public-read"
content_md5="$(bin_md5 < "$file" | base64)"
date="$(date_string)"

url="https://$bucket.s3.amazonaws.com/$file"

tar -cvzf "$file" $@

curl -qsSf -T "$file" \
  -H "Authorization: $(authorization)" \
  -H "x-amz-acl: $acl" \
  -H "Date: $date" \
  -H "Content-MD5: $content_md5" \
  -H "Content-Type: $content_type" \
  "$url"

echo "Cache uploaded to: $url"
