#!/bin/bash

source .env

sum="not a sum"
while true ; do
  new_sum=`ls $IMPOSM3_EXPIRE | md5sum`
  if [ "$sum" != "$new_sum" ]; then
    . seed-by-diffs.sh
  else
    sleep 1
  fi
done
