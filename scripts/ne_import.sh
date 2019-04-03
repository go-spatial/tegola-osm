#!/bin/bash

# This script will install natural earth data (http://www.naturalearthdata.com/downloads/) into a PostGIS database named DB_NAME.
#
# The script assumes the following utilities are installed:
# - psql: PostgreSQL client
#	- ogr2ogr: GDAL vector lib
#	- unzip: decompression util
# - jq: json parsing util
#
# Usage
# 	Set the required env vars, then run
#
#		./ne_import.sh
#
# Important
# - This script is idempotent and will drop and recreate any tables if they already exist. (Specifying the -d flag will also drop and recreate the entire database.)
#	- In order for this script to work the DB_USER must have access to the 'postgres' database to create a new database

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

# NE_MAPPING
# Full path to the ne mapping file we want to use.
# Eg: /ne/config/ne-mapping.json
if [ -z "$NE_MAPPING" ]; then
  printf "Missing env var: NE_MAPPING\n"
  exit 1
fi
if [ ! -f "$NE_MAPPING" ]; then
  printf "NE_MAPPING is an invalid file!\n"
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

# Internal vars
drop_db=false
srid=3857

# Parse command args
while getopts ":sdv" flag; do
  case ${flag} in
    s)
      echo "Reprojecting to SRID: $OPTARG"
      srid=$OPTARG
      ;;
    d)
      echo "Dropping Existing DB"
      drop_db=true
      ;;
    v)
      echo "Running in Verbose Mode"
      set -x
      ;;
    \?)
      printf '\nUnrecognized option: -%s \nUsage: \n[-s SRID] Reproject to SRID \n[-d] Drop existing database \n[-v] Verbose\n' $OPTARG
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

# If -d flag is set then drop and recreate the database
if [[ "$drop_db" = true ]]; then\
  psql "dbname='postgres' host='$DB_HOST' port='$DB_PORT' user='$DB_USER' password='$DB_PW'" -v ON_ERROR_STOP=1 -c "DROP DATABASE IF EXISTS $DB_NAME"
  psql "dbname='postgres' host='$DB_HOST' port='$DB_PORT' user='$DB_USER' password='$DB_PW'" -v ON_ERROR_STOP=1 -c "CREATE DATABASE $DB_NAME"
fi

# Create postgis extension if it doesn't exist
psql "dbname='$DB_NAME' host='$DB_HOST' port='$DB_PORT' user='$DB_USER' password='$DB_PW'" -v ON_ERROR_STOP=1 -c "CREATE EXTENSION IF NOT EXISTS postgis"

# iterate on the layers in the mapping file
LAYERS_JSON=$(cat $NE_MAPPING)
for row in $(echo "${LAYERS_JSON}" | jq -r '.[] | @base64'); do  
  _jq() {
    echo ${row} | base64 --decode | jq -r ${1}
  }

  layer=$(_jq '.layer')
  url="http://www.naturalearthdata.com/http//www.naturalearthdata.com/download/$(_jq '.zoom')/$(_jq '.theme')/${layer}.zip"

  working_dir=${TEMP_DATA_DIR}/${layer}
  mkdir ${working_dir}

  echo "Fetching ${layer}.zip";
  curl -L -o "${working_dir}/${layer}.zip" "${url}"
  unzip -o "${working_dir}/${layer}.zip" -d "${working_dir}"

  # support for archives with more than one shapefile
  for shapefile in ${working_dir}/*.shp; do
    # reproject data and insert into our database
    echo "Importing ${shapefile} into DB"
    OGR_ENABLE_PARTIAL_REPROJECTION=true ogr2ogr -overwrite -unsetFieldWidth -t_srs EPSG:${srid} -nln ${layer} -nlt PROMOTE_TO_MULTI -f PostgreSQL PG:"dbname='$DB_NAME' host='$DB_HOST' port='$DB_PORT' user='$DB_USER' password='$DB_PW'" "${shapefile}"
  done

  # cleanup
  rm -rf "$working_dir"

done