#!/bin/bash
source .env

imposm3 import -connection $OSM_DB_CONN_STR -mapping imposm3-mapping.json -deployproduction
