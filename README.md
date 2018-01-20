# Tegola OSM

This repo houses instructions and configuration files to aid with standing up an OpenStreetMap export and Natural Earth dataset into a PostGIS enabled database that uses [tegola](https://github.com/terranodo/tegola) for creating and serving vector tiles.

## Repo config files

- imposm3.json - an [imposm3](https://github.com/omniscale/imposm3) mapping file for the OSM PBF file.
- tegola.toml - a [tegola](https://github.com/terranodo/tegola) configuration file for the OSM import produced by imposm3.

## Dependencies

- Postgres server with [PostGIS](http://www.postgis.net) enabled.
- imposm3 ([download](https://imposm.org/static/rel/) - linux only)
- tegola ([download](https://github.com/terranodo/tegola/releases))
- [gdal](http://www.gdal.org/) - required for Natural Earth import

## Download the OSM planet database in PBF format

```bash
curl -O http://planet.openstreetmap.org/pbf/planet-latest.osm.pbf
```

## Import the OSM export into PostGIS using imposm3

```bash
./imposm3 import -connection postgis://username:password@host/database-name -mapping imposm3.json -read /path/to/osm/planet-latest.osm.pbf -write
./imposm3 import -connection postgis://username:password@host/database-name -mapping imposm3.json -deployproduction
```

## Import the Natural Earth dataset (requires gdal. can be skipped if you're only interested in OSM)
Update the database credentials inside of `natural_earth.sh`, then run: `./natural_earth.sh`. This will download the natural earth dataset and insert it into PostGIS under a database named `natural_earth`. The script is idempotent.

## Import the OSM land data set
Update the database credentials inside of `osm_land.sh`, then run: `./osm_land.sh`. This will download the natural earth dataset and insert it into PostGIS under a database named `osm`.

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
./tegola -config=tegola.toml
```

Open your browser to localhost and the port you configured tegola to run on (i.e. localhost:8080) to see the built in viewer. 

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