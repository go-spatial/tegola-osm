# Tegola OSM

This repo houses instructions, configuration files, and a docker container to aid with standing up an OpenStreetMap export and Natural Earth dataset into a PostGIS enabled database that uses [tegola](https://github.com/terranodo/tegola) for creating and serving vector tiles.

## Dependencies

* [Docker](https://www.docker.com)
* Postgres server with [PostGIS](http://www.postgis.net) enabled
* tegola ([download](https://github.com/terranodo/tegola/releases))

Additional dependencies if not using docker:

* imposm ([download](https://imposm.org/static/rel/) - linux only)
* [gdal](http://www.gdal.org/) - required for Natural Earth import

## Example Config

* `config/osm-imposm-mapping.json`: An [imposm](https://github.com/omniscale/imposm3) mapping file for mapping the osm pbf data to postgis.
* `config/osm-imposm-config.json`: An [imposm](https://github.com/omniscale/imposm3) config file for replication and srid settings. Note that imposm config properties such as the db connection string, cache and diff directories are not specified via the config but are configured as env vars to docker instead.
* `tegola-osm.toml` - A [tegola](https://github.com/terranodo/tegola) configuration file for the OSM import produced by imposm and osm land.
* `tegola-natural-earth.toml` - A [tegola](https://github.com/terranodo/tegola) configuration file for the natural earth data import.

## Docker Setup

To build the container run the following command from the root directory of this repo:

```bash
docker build -t tegola-osm .
```

The container can also be pulled down from dockerhub.

## Available Scripts / Docker Commands

Each of the bash scripts is installed into the docker container and available as a global command. The scripts could also be run outside of a docker container if you meet the dependencies. The scripts all expect certain env vars to be set.

### scripts/osm_imposm_import.sh

Imports an OSM PBF file into a PostgreSQL/PostGIS instance using imposm `import` command. You are required to provide an imposm-cache and imposm-diff folder to which imposm will persist data. Those same directories must then be used for the osm update script. If you run an import against an existing db and cache/diff folders the existing data will be squashed.

#### Required Env Vars

* `DB_HOST`: PostgreSQL database host name
* `DB_PORT`: PostgreSQL database port
* `DB_NAME`: PostgreSQL database name
* `DB_USER`: PostgreSQL database username
* `DB_PW`: PostgreSQL database password
* `OSM_SOURCE_PBF`: Full path to the osm pbf file that we will import. Eg: `/osm_data/data/north-america-latest.osm.pbf`
* `IMPOSM_CONFIG`: Full path to the imposm config file we want to use. Eg: `/osm_data/config/osm-imposm-config.json`
* `IMPOSM_MAPPING`: Full path to the imposm mapping file we want to use. Eg: `/osm_data/config/osm-imposm-mapping.json`
* `IMPOSM_CACHE_DIR`: Full path to an empty writeable directory where imposm will persist a cache of the import. Eg: `/osm_data/cache`
* `IMPOSM_DIFF_DIR`: Full path to an empty writeable directory where imposm will persist diffs for the import. Eg: `/osm_data/cache`

#### Example Docker Command

All of our data, config files, and directories remain on the host and are exposed to the docker container through bind mounts. We then set the appropriate env vars on the container and reference the internal mount point of each object. This way imposm can not only read data and config dynamically from the host, but it can also persist cache/diff data back.

```bash
docker run -i --rm \
	-u "${UID}" \
	--mount "type=bind,source=/osm_data/data/north-america-latest.osm.pbf,target=/osm/data/north-america-latest.osm.pbf" \
	--mount "type=bind,source=/osm_data/config/osm-imposm-config.json,target=/osm/config/imposm-config.json" \
	--mount "type=bind,source=/osm_data/config/osm-imposm-mapping.json,target=/osm/config/imposm-mapping.json" \
	--mount "type=bind,source=/osm_data/cache,target=/osm/cache" \
	--mount "type=bind,source=/osm_data/diff,target=/osm/diff" \
	-e "DB_HOST=localhost" \
	-e "DB_PORT=5432" \
	-e "DB_NAME=osm_data" \
	-e "DB_USER=postgres" \
	-e "DB_PW=postgres" \
	-e "OSM_SOURCE_PBF=/osm/data/north-america-latest.osm.pbf" \
	-e "IMPOSM_CONFIG=/osm/config/imposm-config.json" \
	-e "IMPOSM_MAPPING=/osm/config/imposm-mapping.json" \
	-e "IMPOSM_CACHE_DIR=/osm/cache" \
	-e "IMPOSM_DIFF_DIR=/osm/diff" \
	"tegola-osm:latest" \
	bash -c "osm_import.sh"
```

### scripts/osm_imposm_update.sh

Updates an existing PostgreSQL/PostGIS instance using imposm `diff` command. In this case we also use osmosis to generate a single changes list which we pass to imposm `diff`. This method is robust and supports updates from different data sources and data subsets across any replication interval. You are required to provide the imposm-cache and imposm-diff folder which was populated during the initial import and prior updates. Additionally, updates require a working directory for osmosis which may or may not be persisted.

#### Required Env Vars

* `DB_HOST`: PostgreSQL database host name
* `DB_PORT`: PostgreSQL database port
* `DB_NAME`: PostgreSQL database name
* `DB_USER`: PostgreSQL database username
* `DB_PW`: PostgreSQL database password
* `OSMOSIS_DIR`: Full path to a working directory for osmosis to create changes lists. Eg: `/osm_data/osmosis`
* `IMPOSM_CONFIG`: Full path to the imposm config file we want to use. Eg: `/osm_data/config/osm-imposm-config.json`
* `IMPOSM_MAPPING`: Full path to the imposm mapping file we want to use. Eg: `/osm_data/config/osm-imposm-mapping.json`
* `IMPOSM_CACHE_DIR`: Full path to an empty writeable directory where imposm will persist a cache of the import. Eg: `/osm_data/cache`
* `IMPOSM_DIFF_DIR`: Full path to an empty writeable directory where imposm will persist diffs for the import. Eg: `/osm_data/cache`

#### Example Docker Command

```bash
docker run -i --rm \
	-u "${UID}" \
	--mount "type=bind,source=/osm_data/osmosis,target=/osm/osmosis" \
	--mount "type=bind,source=/osm_data/config/osm-imposm-config.json,target=/osm/config/imposm-config.json" \
	--mount "type=bind,source=/osm_data/config/osm-imposm-mapping.json,target=/osm/config/imposm-mapping.json" \
	--mount "type=bind,source=/osm_data/cache,target=/osm/cache" \
	--mount "type=bind,source=/osm_data/diff,target=/osm/diff" \
	-e "DB_HOST=localhost" \
	-e "DB_PORT=5432" \
	-e "DB_NAME=osm_data" \
	-e "DB_USER=postgres" \
	-e "DB_PW=postgres" \
	-e "OSMOSIS_DIR=/osm/osmosis" \
	-e "IMPOSM_CONFIG=/osm/config/imposm-config.json" \
	-e "IMPOSM_MAPPING=/osm/config/imposm-mapping.json" \
	-e "IMPOSM_CACHE_DIR=/osm/cache" \
	-e "IMPOSM_DIFF_DIR=/osm/diff" \
	"tegola-osm:latest" \
	bash -c "osm_import.sh"
```

### scripts/ne_import.sh

Imports the Natural Earth data into the specified database. The import process will drop and recreate existing tables. Data is reprojected to 3857 on import but can be changed.

**Note:** If you are looking for the old `natural_earth.sh` script it can be found in `scripts/deprecated/`.

#### Command Args

* `-d` Setting this flag will force the entire database to be dropped and recreated.
* `-s SRID` Setting this will reproject that data to the specified EPSG:SRID during import. 
* `-v` Verbose mode

#### Required Env Vars

* `DB_HOST`: PostgreSQL database host name
* `DB_PORT`: PostgreSQL database port
* `DB_NAME`: PostgreSQL database name
* `DB_USER`: PostgreSQL database username
* `DB_PW`: PostgreSQL database password
* `NE_MAPPING`: Full path to the json mapping file we want to use. Eg: `/ne/config/ne-mapping.json`
* `TEMP_DATA_DIR`: Full path to the directory where this script will temporarily store data. Script user must have permissions to read/write/delete from this directory. Eg: `/tmp`

#### Example Docker Command

```bash
docker run -i --rm \
	-u "${UID}" \
	--mount "type=bind,source=/ne_data/config/ne-mapping.json,target=/ne/mapping.json" \
	--mount "type=bind,source=/tmp,target=/ne/temp" \
	-e "DB_HOST=localhost" \
	-e "DB_PORT=5432" \
	-e "DB_NAME=ne_data" \
	-e "DB_USER=postgres" \
	-e "DB_PW=postgres" \
	-e "NE_MAPPING=/ne/mapping.json" \
	-e "TEMP_DATA_DIR=/ne/temp" \
	"tegola-osm:latest" \
	bash -c "ne_import.sh"
```

### scripts/osm_land_import.sh

Imports the OSM land polygons data into the specified database. The import process will drop and recreate existing tables. Also, you will want to write to the same DB as the main OSM data if you are using the sample `tegola-osm.toml` config.

**Note:** If you are looking for the old `osm_land.sh` script it can be found in `scripts/deprecated/`.

#### Command Args

* `-v` Verbose mode

#### Required Env Vars

* `DB_HOST`: PostgreSQL database host name
* `DB_PORT`: PostgreSQL database port
* `DB_NAME`: PostgreSQL database name
* `DB_USER`: PostgreSQL database username
* `DB_PW`: PostgreSQL database password
* `OSM_LAND_MAPPING`: Full path to the json mapping file we want to use. Eg: `/osm/config/osm-land-mapping.json`
* `TEMP_DATA_DIR`: Full path to the directory where this script will temporarily store data. Script user must have permissions to read/write/delete from this directory. Eg: `/tmp`

#### Example Docker Command

```bash
docker run -i --rm \
	-u "${UID}" \
	--mount "type=bind,source=/osm_data/config/osm-land-mapping.json,target=/osm/config/osm-land-mapping.json" \
	--mount "type=bind,source=/tmp,target=/osm/temp" \
	-e "DB_HOST=localhost" \
	-e "DB_PORT=5432" \
	-e "DB_NAME=ne_data" \
	-e "DB_USER=postgres" \
	-e "DB_PW=postgres" \
	-e "OSM_LAND_MAPPING=/ne/mapping.json" \
	-e "TEMP_DATA_DIR=/ne/temp" \
	"tegola-osm:latest" \
	bash -c "osm_land_import.sh"
```

## Install SQL helper functions
Execute `postgis_helpers.sql` against your OSM database. Currently this contains a single utility function for converting building heights from strings to numbers which is important if you want to extrude buildings for the 3d effect.

```bash
psql -U tegola -d database-name -a -f postgis_helpers.sql
```

## Setup SQL indexes
Execute `postgis_index.sql` against your OSM database.
```bash
psql -U tegola -d database-name -a -f postgis_index.sql
```

## Launch tegola 

```bash
./tegola -config=tegola-osm.toml
```

Open your browser to localhost and the port you configured tegola to run on (i.e. localhost:8080) to see the built in viewer. 

## Data Layers
To view these data layers in a map and query the features for a better understanding of each data layer, use the [Tegola-OSM Inspector](https://osm.tegola.io). The data layers described here are in the "Tegola-OSM" database as laid out in the tegola-osm.toml (i.e., not the Natural Earth database that is specified in tegola-natural-earth.toml). 

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
