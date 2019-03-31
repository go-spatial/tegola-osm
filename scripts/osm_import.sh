#!/bin/bash
set -e

# Validate required env vars

# PG_CONN_STRING
# A connection string for the PostgreSQL/PostGIS database we are targetting.
# Format: postgis://<user>:<password>@<db_host>/<db_name>
if [ -z "$PG_CONN_STRING" ]; then
	printf "Missing env var: PG_CONN_STRING\n"
	exit 1
fi

# OSM_SOURCE_PBF
# Full path to the osm pbf file that we will import.
# Eg: /osm/data/north-america-latest.osm.pbf
if [ -z "$OSM_SOURCE_PBF" ]; then
	printf "Missing env var: OSM_SOURCE_DATA\n"
	exit 1
fi
if [ ! -f "$OSM_SOURCE_PBF" ]; then
	printf "OSM_SOURCE_DATA is an invalid file!\n"
	exit 1
fi

# IMPOSM_CONFIG
# Full path to the imposm config file we want to use.
# Eg: /osm/config/imposm-config.json
if [ -z "$IMPOSM_CONFIG" ]; then
	printf "Missing env var: IMPOSM_CONFIG\n"
	exit 1
fi
if [ ! -f "$IMPOSM_CONFIG" ]; then
	printf "IMPOSM_CONFIG is an invalid file!\n"
	exit 1
fi

# IMPOSM_MAPPING
# Full path to the imposm mapping file we want to use.
# Eg: /osm/config/imposm-mapping.json
if [ -z "$IMPOSM_MAPPING" ]; then
	printf "Missing env var: IMPOSM_MAPPING\n"
	exit 1
fi
if [ ! -f "$IMPOSM_MAPPING" ]; then
	printf "IMPOSM_MAPPING is an invalid file!\n"
	exit 1
fi

# IMPOSM_CACHE_DIR
# Full path to an empty writeable directory where imposm will persist a cache of the import.
# Eg: /osm/cache
if [ -z "$IMPOSM_CACHE_DIR" ]; then
	printf "Missing env var: IMPOSM_CACHE_DIR\n"
	exit 1
fi
if [ ! -d "$IMPOSM_CACHE_DIR" ]; then
	printf "IMPOSM_CACHE_DIR is an invalid directory!\n"
	exit 1
fi

# IMPOSM_DIFF_DIR
# Full path to an empty writeable directory where imposm will persist diffs for the import.
# Eg: /osm/cache
if [ -z "$IMPOSM_DIFF_DIR" ]; then
	printf "Missing env var: IMPOSM_DIFF_DIR\n"
	exit 1
fi
if [ ! -d "$IMPOSM_DIFF_DIR" ]; then
	printf "IMPOSM_DIFF_DIR is an invalid directory!\n"
	exit 1
fi

printf "Running imposm import...\n"
imposm import -config ${IMPOSM_CONFIG} -mapping ${IMPOSM_MAPPING} -connection ${PG_CONN_STRING} -read ${OSM_SOURCE_PBF} -write -diff -cachedir ${IMPOSM_CACHE_DIR} -overwritecache -diffdir ${IMPOSM_DIFF_DIR}

printf "Running imposm deployproduction...\n"
imposm import -config ${IMPOSM_CONFIG} -mapping ${IMPOSM_MAPPING} -connection ${PG_CONN_STRING} -deployproduction