#!/bin/bash

# This script will install natural earth data (http://www.naturalearthdata.com/downloads/) into a PostGIS database named DB_NAME.
# The script assumes the following utilities are installed:
# 	- psql: PostgreSQL client
#	- ogr2ogr: GDAL vector lib
#	- unzip: decompression util
#
# Usage
# 	Set the database connection variables, then run
#
#		./natural_earth.sh
#
# Important
# 	- This script is idempotent and will DROP the natural earth database if it already exists
#	- In order for this script to work the DB_USER must have access to the 'postgres' database to create a new database


set -e

# database connection variables
DB_NAME="natural_earth"
DB_HOST=""
DB_PORT=""
DB_USER=""
DB_PW=""

if [ -r dbcredentials.sh ]
then
	 source dbcredentials.sh
fi

# check our connection string before we do any downloading
psql "dbname='postgres' host='$DB_HOST' port='$DB_PORT' user='$DB_USER' password='$DB_PW'" -c "\q"

# array of natural earth dataset URLs
 dataurls=(
    "http://naciscdn.org/naturalearth/110m/cultural/ne_110m_admin_0_boundary_lines_land.zip"
    "http://naciscdn.org/naturalearth/110m/cultural/ne_110m_admin_0_countries.zip"
    "http://naciscdn.org/naturalearth/110m/cultural/ne_110m_admin_1_states_provinces_lines.zip"
    "http://naciscdn.org/naturalearth/110m/cultural/ne_110m_populated_places.zip"
    "http://naciscdn.org/naturalearth/110m/physical/ne_110m_coastline.zip"
    "http://naciscdn.org/naturalearth/110m/physical/ne_110m_geography_marine_polys.zip"
    "http://naciscdn.org/naturalearth/110m/physical/ne_110m_geography_regions_polys.zip"
    "http://naciscdn.org/naturalearth/110m/physical/ne_110m_rivers_lake_centerlines.zip"
    "http://naciscdn.org/naturalearth/110m/physical/ne_110m_lakes.zip"
    "http://naciscdn.org/naturalearth/110m/physical/ne_110m_glaciated_areas.zip"
    "http://naciscdn.org/naturalearth/110m/physical/ne_110m_land.zip"
    "http://naciscdn.org/naturalearth/110m/physical/ne_110m_ocean.zip"
    "http://naciscdn.org/naturalearth/50m/cultural/ne_50m_admin_0_boundary_lines_land.zip"
    "http://naciscdn.org/naturalearth/50m/cultural/ne_50m_admin_0_boundary_lines_disputed_areas.zip"
    "http://naciscdn.org/naturalearth/50m/cultural/ne_50m_admin_0_boundary_lines_maritime_indicator.zip"
    "http://naciscdn.org/naturalearth/50m/cultural/ne_50m_admin_0_countries.zip"
    "http://naciscdn.org/naturalearth/50m/cultural/ne_50m_admin_0_map_subunits.zip"
    "http://naciscdn.org/naturalearth/50m/cultural/ne_50m_admin_1_states_provinces_lakes.zip" 
    "http://naciscdn.org/naturalearth/50m/cultural/ne_50m_admin_1_states_provinces_lines.zip"
    "http://naciscdn.org/naturalearth/50m/cultural/ne_50m_populated_places.zip"
    "http://naciscdn.org/naturalearth/50m/physical/ne_50m_geographic_lines.zip"
    "http://naciscdn.org/naturalearth/50m/physical/ne_50m_coastline.zip"
    "http://naciscdn.org/naturalearth/50m/physical/ne_50m_antarctic_ice_shelves_lines.zip"
    "http://naciscdn.org/naturalearth/50m/physical/ne_50m_antarctic_ice_shelves_polys.zip"
    "http://naciscdn.org/naturalearth/50m/physical/ne_50m_geography_marine_polys.zip"
    "http://naciscdn.org/naturalearth/50m/physical/ne_50m_geography_regions_elevation_points.zip"
    "http://naciscdn.org/naturalearth/50m/physical/ne_50m_geography_regions_polys.zip"
    "http://naciscdn.org/naturalearth/50m/physical/ne_50m_rivers_lake_centerlines_scale_rank.zip"
    "http://naciscdn.org/naturalearth/50m/physical/ne_50m_rivers_lake_centerlines.zip"
    "http://naciscdn.org/naturalearth/50m/physical/ne_50m_lakes.zip"
    "http://naciscdn.org/naturalearth/50m/physical/ne_50m_glaciated_areas.zip"
    "http://naciscdn.org/naturalearth/50m/physical/ne_50m_land.zip"
    "http://naciscdn.org/naturalearth/50m/physical/ne_50m_ocean.zip"
    "http://naciscdn.org/naturalearth/10m/cultural/ne_10m_admin_0_boundary_lines_land.zip" 
    "http://naciscdn.org/naturalearth/10m/cultural/ne_10m_admin_0_boundary_lines_disputed_areas.zip" 
    "http://naciscdn.org/naturalearth/10m/cultural/ne_10m_parks_and_protected_lands.zip" 
    "http://naciscdn.org/naturalearth/10m/cultural/ne_10m_admin_0_boundary_lines_map_units.zip" 
    "http://naciscdn.org/naturalearth/10m/cultural/ne_10m_admin_0_boundary_lines_maritime_indicator.zip"
    "http://naciscdn.org/naturalearth/10m/cultural/ne_10m_admin_0_label_points.zip"
    "http://naciscdn.org/naturalearth/10m/cultural/ne_10m_admin_0_countries.zip" 
    "http://naciscdn.org/naturalearth/10m/cultural/ne_10m_admin_0_map_subunits.zip"
    "http://naciscdn.org/naturalearth/10m/cultural/ne_10m_admin_1_label_points.zip"   
    "http://naciscdn.org/naturalearth/10m/cultural/ne_10m_admin_1_states_provinces_lines.zip" 
    "http://naciscdn.org/naturalearth/10m/cultural/ne_10m_populated_places.zip" 
    "http://naciscdn.org/naturalearth/10m/cultural/ne_10m_roads.zip" 
    "http://naciscdn.org/naturalearth/10m/cultural/ne_10m_urban_areas.zip" 
    "http://naciscdn.org/naturalearth/10m/physical/ne_10m_geographic_lines.zip" 
    "http://naciscdn.org/naturalearth/10m/physical/ne_10m_coastline.zip" 
    "http://naciscdn.org/naturalearth/10m/physical/ne_10m_antarctic_ice_shelves_lines.zip" 
    "http://naciscdn.org/naturalearth/10m/physical/ne_10m_antarctic_ice_shelves_polys.zip" 
    "http://naciscdn.org/naturalearth/10m/physical/ne_10m_geography_marine_polys.zip" 
    "http://naciscdn.org/naturalearth/10m/physical/ne_10m_geography_regions_elevation_points.zip" 
    "http://naciscdn.org/naturalearth/10m/physical/ne_10m_geography_regions_points.zip" 
    "http://naciscdn.org/naturalearth/10m/physical/ne_10m_geography_regions_polys.zip"
    "http://naciscdn.org/naturalearth/10m/physical/ne_10m_rivers_north_america.zip"
    "http://naciscdn.org/naturalearth/10m/physical/ne_10m_rivers_europe.zip"
    "http://naciscdn.org/naturalearth/10m/physical/ne_10m_rivers_lake_centerlines_scale_rank.zip"     
    "http://naciscdn.org/naturalearth/10m/physical/ne_10m_rivers_lake_centerlines.zip" 
    "http://naciscdn.org/naturalearth/10m/physical/ne_10m_playas.zip"
    "http://naciscdn.org/naturalearth/10m/physical/ne_10m_reefs.zip" 
    "http://naciscdn.org/naturalearth/10m/physical/ne_10m_lakes_historic.zip" 
    "http://naciscdn.org/naturalearth/10m/physical/ne_10m_lakes_north_america.zip"
    "http://naciscdn.org/naturalearth/10m/physical/ne_10m_lakes_europe.zip"
    "http://naciscdn.org/naturalearth/10m/physical/ne_10m_lakes.zip" 
    "http://naciscdn.org/naturalearth/10m/physical/ne_10m_glaciated_areas.zip" 
    "http://naciscdn.org/naturalearth/10m/physical/ne_10m_land.zip"
    "http://naciscdn.org/naturalearth/10m/physical/ne_10m_minor_islands.zip" 
    "http://naciscdn.org/naturalearth/10m/physical/ne_10m_ocean.zip"
)

# remove old database if it exists, create a new one and add the postgis extension
psql "dbname='postgres' host='$DB_HOST' port='$DB_PORT' user='$DB_USER' password='$DB_PW'" -c "DROP DATABASE IF EXISTS $DB_NAME"
psql "dbname='postgres' host='$DB_HOST' port='$DB_PORT' user='$DB_USER' password='$DB_PW'" -c "CREATE DATABASE $DB_NAME"
psql "dbname='$DB_NAME' host='$DB_HOST' port='$DB_PORT' user='$DB_USER' password='$DB_PW'" -c "CREATE EXTENSION postgis"

# iterate our dataurls
for i in "${!dataurls[@]}"; do
	url=${dataurls[$i]}

	echo "fetching $url";
	curl $url > $i.zip;
	unzip $i -d $i

	# support for archives with more than one shapefile
	for f in $i/*.shp; do
		# reproject data to webmercator (3857) and insert into our database
		OGR_ENABLE_PARTIAL_REPROJECTION=true ogr2ogr -unsetFieldWidth -t_srs EPSG:3857 -nlt PROMOTE_TO_MULTI -f PostgreSQL PG:"dbname='$DB_NAME' host='$DB_HOST' port='$DB_PORT' user='$DB_USER' password='$DB_PW'" $f
	done

	# clean up
	rm -rf $i/ $i.zip
done
