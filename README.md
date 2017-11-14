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

## Install SQL helper functions
Execute `postgis_helpers.sql` against your OSM database.
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

## Layer import progress
| imported  | source                                       | table/layer                   | zoom  |
|---|----------------------------------------------|-------------------------------|-------|
|   | ne_110m_rivers_lake_centerlines              |                               		| 0-2   |
|   | ne_110m_lakes                                |                               		| 0-2   |
| y | ne_110m_admin0_boundary_lines_land           | admin_lines                  		| 0-2   |
|   | ne_50m_rivers_lake_centerlines               |                               		| 3-4   |
|   | ne_50m_lakes                                 |                               		| 3-4   |
| y | ne_50m_admin_0_boundary_lines_land and ne_10m_admin_0_boundary_lines_land           | country_lines                		| 3-6   |
| y | ne_50m_admin_0_boundary_lines_disputed_areas and ne_10m_admin_0_boundary_lines_disputed_areas | country_lines_disputed 		| 3-6   |
|   | ne_10m_rivers_lake_centerlines               |                               		| 5-6   |
|   | ne_10m_lakes                                 |                               		| 5-6   |
|   | ne_10m_geography_regions_points              |                               		| 5-6   |
|   | ne_10m_lakes_north_america                   |                               		| 5-6   |
|   | ne_10m_admin_1_states_provinces              |                               | 5-6   |
|   | ne_50m_admin1_states_provinces_lines and ne_10m_admin_1_states_provinces_lines        | state_lines                   | 3-20  |
|   | ne_10m_roads                                 |                               | 5-6   |
|   | ne_10m_roads_north_america                   |                               | 5-6   |
|   | ne_10m_parks_and_protected_lands             |                               | 5-6   |
| y | osm                                          | land                          | 0-20   |
| y | ne_10m_admin_0_countries and osm admin boundaries                 | country_polygons           | 3-20   |
| y | ne_10m_admin_0_label_points                  | country_label_points          | 3-20   |
| y | ne_10m_admin_1_label_points                  | state_label_points            | 5-20  |
| y | osm                                          | landuse_areas                 | 3-20 |
| y | osm                                          | water_lines                   | 8-20 |
| y | osm                                          | water_areas                   | 3-20 |
| y | osm                                          | transport_points              | 14-20 |
| y | osm                                          | transport_lines               | 4-20  |
| y | osm                                          | transport_areas               | 12-20 |
| y | osm                                          | amenity_points                | 14-20 |
| y | osm                                          | amenity_areas                 | 14-20 |
| y | osm                                          | other_points                  | 14-20 |
| y | osm                                          | other_lines                   | 14-20 |
| y | osm                                          | other_areas                   | 6-20 |
| y | osm                                          | buildings                     | 14-20 |
