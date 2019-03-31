#!/bin/bash

# Validate required env vars

# PG_CONN_STRING
# A connection string for the PostgreSQL/PostGIS database we are targetting.
# Format: postgis://<user>:<password>@<db_host>/<db_name>
if [ -z "$PG_CONN_STRING" ]; then
	printf "Missing env var: PG_CONN_STRING\n"
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

# OSMOSIS_DIR
# Full path to a working directory for osmosis to create changes lists
# Eg: /osm/osmosis
if [ -z "$OSMOSIS_DIFF_DIR" ]; then
	printf "Missing env var: OSMOSIS_DIFF_DIR\n"
	exit 1
fi
if [ ! -d "$OSMOSIS_DIFF_DIR" ]; then
	printf "OSMOSIS_DIFF_DIR is an invalid directory!\n"
	exit 1
fi

printf "Initializing osmosis directory...\n"
cp ${IMPOSM_DIFF_DIR}/last.state.txt ${OSMOSIS_DIFF_DIR}/state.txt

cat > ${OSMOSIS_DIFF_DIR}/configuration.txt <<EOL
baseUrl=$(perl -ne '/replicationUrl=(.*)$/ and print $1' ${OSMOSIS_DIFF_DIR}/state.txt)
maxInterval=0
EOL

printf "Building changes list with osmosis...\n"
cd ${DATA_ROOT_DIR}/osmosis
osmosis --read-replication-interval workingDirectory=${OSMOSIS_DIFF_DIR} --write-xml-change ${OSMOSIS_DIFF_DIR}/update.osc.gz

log_info "Running imposm diff update...\n"
imposm diff -config ${IMPOSM_CONFIG} -mapping ${IMPOSM_MAPPING} -connection ${PG_CONN_STRING} -cachedir ${IMPOSM_CACHE_DIR} -diffdir ${IMPOSM_DIFF_DIR} ${OSMOSIS_DIFF_DIR}/update.osc.gz