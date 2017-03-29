#!/bin/bash

set -e

DB_NAME="natural_earth"

# array of natural earth dataset URLs
 dataurls=(
	"http://naciscdn.org/naturalearth/110m/physical/ne_110m_land.zip"
	"http://naciscdn.org/naturalearth/110m/cultural/ne_110m_admin_0_boundary_lines_land.zip"
	"http://naciscdn.org/naturalearth/50m/physical/ne_50m_land.zip"
	"http://naciscdn.org/naturalearth/50m/cultural/ne_50m_admin_0_boundary_lines_land.zip"
	"http://naciscdn.org/naturalearth/50m/cultural/ne_50m_admin_0_boundary_lines_disputed_areas.zip"
	"http://naciscdn.org/naturalearth/10m/physical/ne_10m_land.zip"
	"http://naciscdn.org/naturalearth/10m/cultural/ne_10m_admin_0_boundary_lines_land.zip"
	"http://naciscdn.org/naturalearth/10m/cultural/ne_10m_admin_0_boundary_lines_disputed_areas.zip"
)

psql postgres -c "DROP DATABASE IF EXISTS $DB_NAME"
psql postgres -c "CREATE DATABASE $DB_NAME"
psql $DB_NAME -c "CREATE EXTENSION postgis"

# iterate our dataurls
for i in "${!dataurls[@]}"; do
	url=${dataurls[$i]}

	echo "fetching $url";
	curl $url > $i.zip;
	unzip $i -d $i

	# reproject data to webmercator (3857) and insert into our database
	OGR_ENABLE_PARTIAL_REPROJECTION=true ogr2ogr -t_srs EPSG:3857 -nlt PROMOTE_TO_MULTI -f PostgreSQL PG:dbname=$DB_NAME $i/*.shp

	# clean up
	rm -rf $i/ $i.zip
done