#!/bin/bash
source .env

export GOMAXPROCS=32

imposm3 import -connection $OSM_DB_CONN_STR -write -mapping imposm3-mapping.json -diff -cachedir $IMPOSM3_CACHE -diffdir $IMPOSM3_DIFF
