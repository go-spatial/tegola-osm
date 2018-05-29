#!/bin/bash
source .env

db_con=postgis://$OSM_DB_USER:$OSM_DB_PASS@$OSM_DB_HOST:$OSM_DB_PORT/osm_dev

imposm3 run -connection $db_con -mapping imposm3-mapping.json -cachedir $IMPOSM3_CACHE -diffdir $IMPOSM3_DIFF -expiretiles-dir $IMPOSM3_EXPIRE
