#!/bin/bash
source .env

imposm3 run -connection $OSM_DB_CONN_STR -mapping imposm3-mapping.json -cachedir $IMPOSM3_CACHE -diffdir $IMPOSM3_DIFF -expiretiles-dir $IMPOSM3_EXPIRE
