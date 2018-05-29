#!/bin/bash
source .env

db_con=postgis://$OSM_DB_USER:$OSM_DB_PASS@$OSM_DB_HOST:$OSM_DB_PORT/osm_dev

export GOMAXPROCS=32

imposm3 import -connection $db_con -write -mapping imposm3-mapping.json -diff -cachedir $IMPOSM3_CACHE -diffdir $IMPOSM3_DIFF
