#!/bin/bash

# This script will install the Open Street Maps land polygons (simplified for zooms 0-9 and split for zooms 10-20).
#
# The script assumes the following utilities are installed:
# - psql: PostgreSQL client
# - ogr2ogr: GDAL vector lib
# - unzip: decompression util
# - jq: json parsing util
#
# Usage
#   Set the required env vars, then run
#
#		./osm_land_import.sh
#
# Important
#	- The tegola config file is expecting these layers to be in the same database as the rest of the OSM data imported using imposm3
#	- This script will overwrite the tables if they already exist.

set -e

# Validate required env vars

# DB_HOST, DB_PORT, DB_NAME, DB_USER, DB_PW
# All db connection parameters for postgres.
if [ -z "$DB_HOST" ]; then
  printf "Missing env var: DB_HOST\n"
  exit 1
fi
if [ -z "$DB_PORT" ]; then
  printf "Missing env var: DB_PORT\n"
  exit 1
fi
if [ -z "$DB_NAME" ]; then
  printf "Missing env var: DB_NAME\n"
  exit 1
fi
if [ -z "$DB_USER" ]; then
  printf "Missing env var: DB_USER\n"
  exit 1
fi
if [ -z "$DB_PW" ]; then
  printf "Missing env var: DB_PW\n"
  exit 1
fi

# OSM_LAND_MAPPING
# Full path to the osm land mapping file we want to use.
# Eg: /ne/config/osm-land-mapping.json
if [ -z "$OSM_LAND_MAPPING" ]; then
  printf "Missing env var: OSM_LAND_MAPPING\n"
  exit 1
fi
if [ ! -f "$OSM_LAND_MAPPING" ]; then
  printf "OSM_LAND_MAPPING is an invalid file!\n"
  exit 1
fi

# TEMP_DATA_DIR
# Full path to the directory where this script will temporarily store data.
# Script user must have permissions to read/write/delete from this directory.
# Eg: /tmp
if [ -z "$TEMP_DATA_DIR" ]; then
  printf "Missing env var: TEMP_DATA_DIR\n"
  exit 1
fi
if [ ! -d "$TEMP_DATA_DIR" ]; then
  printf "TEMP_DATA_DIR is an invalid directory!\n"
  exit 1
fi

# Parse command args
while getopts "v" flag; do
  case ${flag} in
    v)
      echo "Running in Verbose Mode"
      set -x
      ;;
    \?)
      printf '\nUnrecognized option: -%s \nUsage: \n[-v] Verbose\n' $OPTARG
      exit 2
      ;;
    :)
      echo "Option -$OPTARG requires an argument"
      exit 2
      ;;
  esac
done

# check our connection string before we go any farther
psql "dbname='$DB_NAME' host='$DB_HOST' port='$DB_PORT' user='$DB_USER' password='$DB_PW'" -c "\q"

# iterate on the layers in the mapping file
LAYERS_JSON=$(cat $OSM_LAND_MAPPING)
for row in $(echo "${LAYERS_JSON}" | jq -r '.[] | @base64'); do  
  _jq() {
    echo ${row} | base64 --decode | jq -r ${1}
  }

  layer=$(_jq '.layer')
  url="http://data.openstreetmapdata.com/$(_jq '.filename')"
  srid=$(_jq '.srid')

  working_dir=${TEMP_DATA_DIR}/${layer}
  mkdir ${working_dir}

  echo "Fetching ${layer}.zip";
  curl -L -o "${working_dir}/${layer}.zip" "${url}"
  unzip -j -o "${working_dir}/${layer}.zip" -d "${working_dir}"

  shapefile=$working_dir/$(find "$working_dir" -name '*.shp' -exec basename {} \; -quit)

  # reproject data and insert into our database
  echo "Importing ${shapefile} into DB"
  OGR_ENABLE_PARTIAL_REPROJECTION=true ogr2ogr -overwrite -t_srs EPSG:${srid} -nln ${layer} -nlt PROMOTE_TO_MULTI -f PostgreSQL PG:"dbname='$DB_NAME' host='$DB_HOST' port='$DB_PORT' user='$DB_USER' password='$DB_PW'" "${shapefile}"

  # cleanup
  rm -rf "$working_dir"

done