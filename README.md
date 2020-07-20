# Tegola OSM

This repo houses instructions and configuration files to aid with standing up an OpenStreetMap export and Natural Earth dataset into a PostGIS enabled database that uses [tegola](https://github.com/terranodo/tegola) for creating and serving vector tiles.

## Dependencies

If you want to use these scripts you will need the following:

- Postgres server with [PostGIS](http://www.postgis.net) enabled.
- imposm3 ([download](https://imposm.org/static/rel/) - linux only)
- tegola ([download](https://github.com/terranodo/tegola/releases))
- [gdal](http://www.gdal.org/) - required for Natural Earth import

## Basic overview

The scripts in this repo prepare 2 databases with data from 3 sources:

1. [OpenStreetMap](https://wiki.openstreetmap.org/wiki/Main_Page) - highly detailed data for roads, rail, buildings, rivers, lakes, and more.
2. [Natural Earth](https://www.naturalearthdata.com/) - data for country borders, state lines, land, major roads, and more.
3. [OpenStreetMap Land Polygons](https://osmdata.openstreetmap.de/data/land-polygons.html) - high detail polygons for landmass.

To import all this data into your databases the scripts use Imposm3 for OpenStreetMap data (1) and Gdal for both NaturalEarth and OSM land polygon data (2+3).

Once the data has been imported it is ready to serve with Tegola.

## Repo config files
The following files allow you to configure what data is imported into your databases and how the data is served by Tegola:

- imposm3.json - an [imposm3](https://github.com/omniscale/imposm3) mapping file for the OSM PBF file.
- tegola.toml - a [tegola](https://github.com/terranodo/tegola) configuration file for how to serve the OSM data created by Imposm.

## Getting started

## Step 1. Prepare databases

Create two databases called `osm` and `natural_earth` and enable the extensions `postgis` and `hstore` on both of them.

```
createdb -E utf8 -O my_pg_user osm
psql -d osm -c "CREATE EXTENSION postgis;"
psql -d osm -c "CREATE EXTENSION hstore;"

createdb -E utf8 -O my_pg_user natural_earth
psql -d natural_earth -c "CREATE EXTENSION postgis;"
psql -d natural_earth -c "CREATE EXTENSION hstore;"
```

The steps below will import OSM (1) and OSM land (3) data into "osm" and Natural Earth (2) data into "natural_earth".

## Step 2. Download your desired OSM dataset in PBF format

Since processing map data can be time-consuming it's best to start with a city rather than the whole planet. You can download OSM data for individual cities at [Geofabrik](http://download.geofabrik.de/). For this guide, we will use London.

In this repo's root directory run the following:

* [ ] `curl -O 'http://download.geofabrik.de/europe/great-britain/england/greater-london-latest.osm.pbf'`

## Step 3. Import the OSM export into PostGIS using Imposm3

You will use Imposm to map the data from the OSM dataset (1) into your osm database. Imposm requires you to do this in [2 steps](https://imposm.org/docs/imposm3/latest/tutorial.html#importing).

* [ ] `./imposm3 import -connection postgis://your_pg_user:your_password@localhost/osm -mapping imposm3.json -read ./greater-london-latest.osm.pbf -write`

* [ ] `./imposm3 import -connection postgis://your_pg_user:your_password@localhost/osm -mapping imposm3.json -deployproduction`

The osm database now has all the OSM data (1) ready for use.

## Step 4. Import the OSM Land and Natural Earth dataset

Now you need to add the OSM land polygon data (3) to the osm database. Update the following lines in the `osm_land.sh` script with your database details e.g.

```
DB_NAME="osm"
DB_HOST="localhost"
DB_PORT="5432"
DB_USER="your_pg_user"
DB_PW="your_password"
```

The Natural Earth data will be imported into the natural_earth database you created earlier. Update the same lines in the `natural_earth.sh` script with the relevant details. E.g.
```
DB_NAME="natural_earth"
DB_HOST="localhost"
DB_PORT="5432"
DB_USER="your_pg_user"
DB_PW="your_password"
```

Then run each file: `./natural_earth.sh && ./osm_land.sh`.

This will download the natural earth and osm land datasets and insert them into PostGIS under your `natural_earth` and `osm` databases respectively.

Note: For debugging options and more advanced ways to complete this step see "Alternative ways to import the OSM Land and Natural Earth dataset" below.

## Step 5. Install SQL helper functions
Execute `postgis_helpers.sql` against your OSM database. Currently, this contains a single utility function for converting building heights from strings to numbers which is important if you want to extrude buildings for the 3d effect.

* [ ] `psql -U your_pg_user -d osm -a -f postgis_helpers.sql`

## Step 6. Setup SQL indexes
Execute `postgis_index.sql` against your OSM database.

* [ ] `psql -U your_pg_user -d osm -a -f postgis_index.sql`

## Step 7. Launch Tegola

* [ ] `./tegola serve --config tegola.toml`

Open your browser to localhost and the port you configured Tegola to run on (i.e. localhost:8080) to see the built-in viewer.

## Alternative ways to import the OSM Land and Natural Earth dataset

Step 4 took a simple approach to configure the osm_land.sh and natural_earths.sh scripts by simply having you hard code them with your DB credentials. However, there are two other options this step can be accomplished by which might suit your needs better in production environments.

### Option 2: Create a dbcredentials.sh file
Create a `dbcredentials.sh` file which will be shared with the `osm_land` script.  This option is ideal for when the `natural_earth` and `osm` databases will reside on the same database server, and will use the same credentials. Ensure that the following variables are defined in your file:

```bash
DB_HOST="mydbhost"
DB_PORT="myport"
DB_USER="myuser"
DB_PW="mypassword"
```
Once you have configured the `dbcredentials.sh` file, run the scripts as above:

* [ ] `./natural_earth.sh && ./osm_land.sh`

### Option 3:
Create separate configuration files in the same pattern as the above `dbcredentials.sh` file and pass the path to the config file using the `-c` option.  This is ideal if you have two different servers for the databases. Ensure the file you create follows this format:
```bash
DB_NAME="mydb"
DB_HOST="mydbhost"
DB_PORT="myport"
DB_USER="myuser"
DB_PW="mypassword"
```
Once you have configured the files, run the scripts with the `-c` flag and provide the path to the credentials file, ie:

* [ ] `./natural_earth.sh -c natural_earth_creds.sh && ./osm_land.sh -c osm_creds.sh`

### Advanced Usage
Both scripts support a `-v` flag for debugging.  `natural_earth.sh` also supports a `-d` flag, which will drop the existing natural earth database prior to import if set. Since the `osm_land.sh` imports into the osm database which is shared with other data, it lacks this functionality.  Instead, only the relevant tables are dropped.

## Data Layers
To view these data layers in a map and query the features for a better understanding of each data layer, use the [Tegola-OSM Inspector](https://osm.tegola.io). The data layers described here are in the "Tegola-OSM" database as laid out in the tegola.toml (i.e., not the Natural Earth database that is specified in tegola-natural-earth.toml).

| source | Description |
|--------|-------------|
|ne      | Natural Earth data, version 4 |
|osm     | OpenStreetMap data, current |
|osm land| OpenStreetMap-derived land polygons from openstreetmapdata.com, currentness depends on last pull |

>**Note:** All layers also have the data fields: layer id and geometry. An empty where column means that all features are retained.

### populated_places
*points*

| zoom | source   | table/layer   | data fields          | where |
|------|----------|---------------|----------------------|-------|
| 0-2  | ne       | ne_110m_populated_places  | scalerank, labelrank, name, min_zoom, featurecla, rank_max |
| 3-4  | ne       | ne_50m_populated_places   | scalerank, labelrank, name, min_zoom, featurecla, rank_max |
| 5-20 | ne       | ne_10m_populated_places   | scalerank, labelrank, name, min_zoom, featurecla, rank_max |


### country_lines
| zoom | source   | table/layer   | data fields          | where |
|------|----------|---------------|----------------------|-------|
| 0-2  | ne       | ne_110m_admin_0_boundary_lines_land  | featurecla, name, min_zoom |
| 3-4  | ne       | ne_50m_admin_0_boundary_lines_land   | featurecla, name, min_zoom |
| 5-10 | ne       | ne_10m_admin_0_boundary_lines_land   | featurecla, name, min_zoom |


### country_lines_disputed
*lines*

| zoom | source   | table/layer   | data fields          | where |
|------|----------|---------------|----------------------|-------|
| 3-4  | ne       | ne_50m_ne_50m_admin_0_boundary_lines_disputed_areas   | featurecla, name, min_zoom |
| 5-10 | ne       | ne_10m_ne_50m_admin_0_boundary_lines_disputed_areas   | featurecla, name, min_zoom |


### country_label_points
| zoom | source   | table/layer   | data fields          | where |
|------|----------|---------------|----------------------|-------|
| 3-20 | ne       | ne_10m_admin_0_label_points  | sr_subunit, scalerank |


### country_polygons
| zoom | source   | table/layer   | data fields          | where |
|------|----------|---------------|----------------------|-------|
| 0-2  | ne       | ne_110m_admin_0_countries  | featurecla, name, name_long, abbrev, adm0_a3, min_zoom, min_label, max_label |
| 3-4  | ne       | ne_50m_admin_0_countries   | featurecla, name, name_long, abbrev, adm0_a3, min_zoom, min_label, max_label |
| 5-10 | ne       | ne_10m_admin_0_countries   | featurecla, name, name_long, abbrev, adm0_a3, min_zoom, min_label, max_label |


### state_lines
| zoom | source   | table/layer   | data fields          | where |
|------|----------|---------------|----------------------|-------|
| 0-2  | ne       | ne_110m_admin_1_states_provinces_lines  | featurecla, name, adm0_name, min_zoom |
| 3-4  | ne       | ne_50m_admin_1_states_provinces_lines   | featurecla, name, adm0_name, min_zoom |
| 5-10 | ne       | ne_10m_admin_1_states_provinces_lines   | featurecla, name, adm0_name, min_zoom |


### land
*polygons*

| zoom | source   | table/layer   | data fields          | where |
|------|----------|---------------|----------------------|-------|
| 0-2  | ne       | ne_110m_land  | featurecla, min_zoom |
| 3-4  | ne       | ne_50m_land   | featurecla, min_zoom |
| 5-7  | ne       | ne_10m_land   | featurecla, min_zoom |
| 8-20 | osm land | land_polygons |                      |


### admin_lines
| zoom | source    | table/layer            | data fields             | where                                 |
|------|-----------|------------------------|-------------------------|---------------------------------------|
| 8-12 | osm       | admin_boundaries_8-12  | admin_level, name, type | admin_level IN (1,2,3,4,5,6,7,8)      |
| 13-20| osm       | admin_boundaries_13-20 | admin_level, name, type | admin_level IN (1,2,3,4,5,6,7,8,9,10) |


### state_label_points
| zoom | source   | table/layer   | data fields          | where |
|------|----------|---------------|----------------------|-------|
| 3-20 | ne       | ne_10m_admin_1_label_points  | name, scalerank |


### landuse_areas
Nature reserves, military land, forest, leisure, wood, etc.
*polygons*

| zoom | source   | table/layer   | data fields                       | where |
|------|----------|---------------|-----------------------------------|-------|
| 3-5  | osm       | landuse_areas_gen0  | name, class, type, area    | type IN ('forest','wood','nature reserve', 'nature_reserve', 'military') AND area > 1000000000 |
| 6-9  | osm       | landuse_areas_gen0_6| name, class, type, area    | type IN ('forest','wood','nature reserve', 'nature_reserve', 'military') AND area > 100000000 |
| 10-12| osm       | landuse_areas_gen1  | name, class, type, area    |
| 13-20| osm       | landuse_areas       | name, class, type, area    |


### water_areas
*polygons*

| zoom | source   | table/layer   | data fields                       | where |
|------|----------|---------------|-----------------------------------|-------|
| 3-5  | osm       | water_areas_gen0  | name, class, type, area    | type IN ('water', 'pond', 'basin', 'canal', 'mill_pond', 'riverbank') AND area > 1000000000 |
| 6-9  | osm       | water_areas_gen0_6| name, class, type, area    | type IN ('water', 'pond', 'basin', 'canal', 'mill_pond', 'riverbank') AND area > 100000000 |
| 10-12| osm       | water_areas_gen1  | name, class, type, area    | type IN ('water', 'pond', 'basin', 'canal', 'mill_pond', 'riverbank') AND area > 1000 |
| 13-20| osm       | water_areas       | name, class, type, area    | type IN ('water', 'pond', 'basin', 'canal', 'mill_pond', 'riverbank', 'dock') |


### water_lines
| zoom | source   | table/layer   | data fields                       | where |
|------|----------|---------------|-----------------------------------|-------|
| 8-12 | osm       | water_lines_gen0  | name, type      | type IN ('river', 'canal') |
| 13-14| osm       | water_lines_gen1  | name, type      | type IN ('river', 'canal', 'stream', 'ditch', 'drain', 'dam') |
| 15-20| osm       | water_lines       | name, type      | type IN ('river', 'canal', 'stream', 'ditch', 'drain', 'dam') |


### transport_lines
Roads, airport runways, ferry routes, paths, etc.

| zoom | source   | table/layer   | data fields                       | where |
|------|----------|---------------|-----------------------------------|-------|
| 3-4  | ne       | ne_10m_roads_3        | name, min_zoom, min_label, type, label                       | min_zoom < 5 AND type <> 'Ferry Route' |
| 5-6  | ne       | ne_10m_roads_5        | name, min_zoom, min_label, type, label                       | min_zoom <= 7  AND type <> 'Ferry Route' |
| 7-8  | osm      | transport_lines_gen0  | type, tunnel, bridge, ref                                    | type IN ('motorway','trunk','motorway_link','trunk_link','primary') AND tunnel = 0 AND bridge = 0 |
| 9-10 | osm      | transport_lines_gen1  | ref, class, type                                             | type IN ('motorway', 'trunk', 'primary', 'primary_link', 'secondary', 'motorway_link', 'trunk_link') |
| 11-12| osm      | transport_lines_11-12 | name, ref, class, type, tunnel, bridge, access, service      | type IN ('motorway', 'motorway_link', 'trunk', 'trunk_link', 'primary', 'primary_link', 'secondary', 'secondary_link', 'tertiary', 'tertiary_link', 'rail', 'taxiway', 'runway', 'apron') |
| 13   | osm      | transport_lines_13    | name, ref, class, type, tunnel, bridge, access, service      | type IN ('motorway', 'motorway_link', 'trunk', 'trunk_link', 'primary', 'primary_link', 'secondary', 'secondary_link', 'tertiary', 'tertiary_link', 'rail', 'residential', 'taxiway', 'runway', 'apron') |
| 14-20| osm      | transport_lines_14-20 | name, ref, class, type, tunnel, bridge, access, service      |


### transport_areas
Airports, etc.
*polygons*

| zoom | source   | table/layer   | data fields                       | where |
|------|----------|---------------|-----------------------------------|-------|
| 12-20| osm       | transport_areas  | name, class, type      |


### transport_points
Airports, helipads, etc.

| zoom | source   | table/layer   | data fields                       | where |
|------|----------|---------------|-----------------------------------|-------|
| 14-20| osm       | transport_points  | name, class, type      |


### amenity_areas
Fire stations, banks, embassies, government, police stations, schools, universities, etc.
*polygons*

| zoom | source   | table/layer   | data fields                       | where |
|------|----------|---------------|-----------------------------------|-------|
| 14-20| osm       | amenity_areas  | name, type      |

### amenity_points
Fire stations, banks, embassies, government, police stations, schools, universities, etc.

| zoom | source   | table/layer   | data fields                       | where |
|------|----------|---------------|-----------------------------------|-------|
| 14-20| osm       | amenity_points  | name, type      |


### other_points
Man made, historic, military, barriers, power towers, etc.

| zoom | source   | table/layer   | data fields                       | where |
|------|----------|---------------|-----------------------------------|-------|
| 14-20| osm       | other_points  | name, class, type      |


### other_lines
Man made, historic, military, barriers, power lines, etc.

| zoom | source   | table/layer   | data fields                       | where |
|------|----------|---------------|-----------------------------------|-------|
| 14-20| osm       | other_lines  | name, class, type      |


### other_areas
*polygons*
Man made, historic, military, power, barriers, piers, etc.

| zoom | source   | table/layer   | data fields                       | where |
|------|----------|---------------|-----------------------------------|-------|
| 6-8  | osm       | other_areas_filter  | name, class, type      | area > 1000000 |
| 9-20 | osm       | other_areas         | name, class, type      | |


### buildings
*polygons*

| zoom | source   | table/layer   | data fields                       | where |
|------|----------|---------------|-----------------------------------|-------|
| 14-20| osm       | buildings  | name, height, type      |

# How long does it take to import the entire planet?
If you run this import, please send in a PR to report your import machine specs and how long it takes.

**@peldhose**: 11.30 hours on a Google cloud server with 8 vCPU, 30GB RAM and 1TB storage (400GB used)  
**@SahAssar** 15.43 hours on a Dell XPS 13 9380 i7-8565U 16GB RAM and 1TB SSD (375GB used by postgres after import)
