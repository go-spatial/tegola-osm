#!/bin/bash

# This script will install the Open Street Maps land polygons (simplified for zooms 0-9 and split for zooms 10-20).
#
# The script assumes the following utilities are installed:
# 	- psql: PostgreSQL client
#	- ogr2ogr: GDAL vector lib
#	- unzip: decompression util
#
# Usage
# 	Set the database connection variables, then run
#
#		./osm_land.sh
#
# Important
#	- The tegola config file is expecting these layers to be in the same database as the rest of the OSM data imported using imposm3
#	- This script will drop the tables simplified_land_polygons and land_polygons if they exist and then replace them.

set -e

# database connection variables
DB_NAME="osm"
DB_HOST=""
DB_PORT=""
DB_USER=""
DB_PW=""
if [ -r dbcredentials.sh ]
then
	 source dbcredentials.sh
fi

# array of natural earth dataset URLs
 dataurls=(
	"http://data.openstreetmapdata.com/simplified-land-polygons-complete-3857.zip"
	"http://data.openstreetmapdata.com/land-polygons-split-3857.zip"
)

 psql "dbname='postgres' host='$DB_HOST' port='$DB_PORT' user='$DB_USER' password='$DB_PW'" -c "DROP TABLE IF EXISTS simplified_land_polygons"
 psql "dbname='postgres' host='$DB_HOST' port='$DB_PORT' user='$DB_USER' password='$DB_PW'" -c "DROP TABLE IF EXISTS land_polygons"

# iterate our dataurls
for i in "${!dataurls[@]}"; do
	url=${dataurls[$i]}

	echo "fetching $url";
	curl $url > $i.zip;
	unzip $i -d $i

	shape_file=$(find $i -type f -name "*.shp")

	echo $shape_file

	# reproject data to webmercator (3857) and insert into our database
	OGR_ENABLE_PARTIAL_REPROJECTION=true ogr2ogr -t_srs EPSG:3857 -nlt PROMOTE_TO_MULTI -f PostgreSQL PG:"dbname='$DB_NAME' host='$DB_HOST' port='$DB_PORT' user='$DB_USER' password='$DB_PW'" $shape_file

	# clean up
	rm -rf $i/ $i.zip
done
