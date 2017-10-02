# Tegola OSM

This repo houses instructions and configuration files to aid with standing up an OpenStreetMap export into a PostGIS enabled database that uses [tegola](https://github.com/terranodo/tegola) for creating and serving vector tiles.

## Repo config files

- imposm3.json - an [imposm3](https://github.com/omniscale/imposm3) mapping file for the OSM PBF file.
- tegola.toml - a [tegola](https://github.com/terranodo/tegola) configuration file for the OSM import produced by imposm3.
- mapbox.json - a [mapbox-gl style](https://www.mapbox.com/mapbox-gl-js/style-spec/) config used for client side rendering.

## Dependencies

- Postgres server with [PostGIS](http://www.postgis.net) enabled.
- imposm3 ([download](https://imposm.org/static/rel/) - linux only)
- tegola ([download](https://github.com/terranodo/tegola/releases))

## Download the OSM planet database in PBF format

```bash
curl -O http://planet.openstreetmap.org/pbf/planet-latest.osm.pbf
```

## Import the OSM export into PostGIS using imposm3

```bash
./imposm3 import -connection postgis://username:password@host/database-name -mapping imposm3.json -read /path/to/osm/planet-latest.osm.pbf -write
```

## Launch tegola 

```bash
./tegola -config=tegola.toml
```

## Layer import progress
| imported  | source                                       | table/layer                   | zoom  |
|---|----------------------------------------------|-------------------------------|-------|
|   | ne_110m_rivers_lake_centerlines              |                               		| 0-2   |
|   | ne_110m_lakes                                |                               		| 0-2   |
| y | ne_110m_admin0_boundary_lines_land           | admin_boundaries_0-2          		| 0-2   |
|   | ne_50m_rivers_lake_centerlines               |                               		| 3-4   |
|   | ne_50m_lakes                                 |                               		| 3-4   |
| y | ne_50m_admin_0_boundary_lines_land           | admin_boundaries_3-4          		| 3-4   |
| y | ne_50m_admin_0_boundary_lines_disputed_areas | admin_boundaries_disputed_3-4 		| 3-4   |
| y | ne_50m_admin1_states_provinces_lines         | admin_states_provinces_lines_3-4   | 3-4   |
|   | ne_10m_rivers_lake_centerlines               |                               		| 5-6   |
|   | ne_10m_lakes                                 |                               		| 5-6   |
|   | ne_10m_geography_regions_points              |                               		| 5-6   |
|   | ne_10m_lakes_north_america                   |                               		| 5-6   |
| y | ne_10m_admin_0_boundary_lines_land           | admin_boundaries_5-6          		| 5-6   |
| y | ne_10m_admin_0_boundary_lines_disputed_areas | admin_boundaries_disputed_5-6 		| 5-6   |
|   | ne_10m_admin_1_states_provinces              |                               | 5-6   |
| y | ne_10m_admin_1_states_provinces_lines        | admin_states_provinces_lines_5-20  | 5-20   |
|   | ne_10m_roads                                 |                               | 5-6   |
|   | ne_10m_roads_north_america                   |                               | 5-6   |
|   | ne_10m_parks_and_protected_lands             |                               | 5-6   |
| y | ne_10m_admin_0_countries                     | admin_countries_3-7           | 3-7   |
| y | ne_10m_admin_1_label_points                  | admin_label_points_5-20       | 5-20   |
| y | ne_10m_admin_0_label_points                  | admin_0_label_points_3-20       | 3-20   |
| y | osm                                          | land_0-9                      | 0-9   |
| y | osm                                          | land_10-20                    | 10-20 |
| y | osm                                          | landusages_gen0           | 4-9   |
| y | osm                                          | landusages_gen1           | 10-12 |
| y | osm                                          | landusages                | 13-20 |
| y | osm                                          | waterways_gen0            | 8-12  |
| y | osm                                          | waterways_gen1            | 13-14 |
| y | osm                                          | waterways                 | 15-20 |
| y | osm                                          | waterareas_gen0           | 4-9   |
| y | osm                                          | waterareas_gen1           | 10-12 |
| y | osm                                          | waterareas                | 13-20 |
| y | osm                                          | boundaries_polygon            | 5-20  |
|   | osm                                          | barriers_lines                | 16-20 |
|   | osm                                          | barriers_points               | 17-20 |
| y | osm                                          | buildings_polygons            | 14-20 |
|   | osm                                          | military_polygons             | 4-20  |
| y | osm                                          | roads_gen0                | 5-8   |
| y | osm                                          | roads_gen1                | 9-10  |
| y | osm                                          | roads_11-12               | 11-12 |
| y | osm                                          | roads_13                  | 13    |
| y | osm                                          | roads_14-20               | 14-20 |
|   | osm                                          | amenities                     | 14-20 |
|   | osm                                          | aviation_points               | 10-20 |
|   | osm                                          | aviation_lines                | 14-20 |
|   | osm                                          | aviation_polygons             | 14-20 |
|   | osm                                          | power_lines                   | 16-20 |
|   | osm                                          | railway_lines_gen0            | 5-8   |
|   | osm                                          | railway_lines_gen1            | 9-10  |
|   | osm                                          | railway_lines                 | 11-20 |
|   | osm                                          | leisure_points                | 14-20 |
|   | osm                                          | leisure_polygons              | 7-20  |
|   | osm                                          | place_points                  | 3-20  |
|   | osm                                          | natural_polygons              | 4-20  |
