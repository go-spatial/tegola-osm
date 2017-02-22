# Tegola OSM

This repo houses instructions and configuration files to aid with standing up an Open Street Map export into a PostGIS enabled database that uses [tegola](https://github.com/terranodo/tegola) for creating and serving vector tiles.

## Repo config files

- imposm3.json - an [imposm3](https://github.com/omniscale/imposm3) mapping file for the OSM PBF file.
- tegola.toml - a [tegola](https://github.com/terranodo/tegola) configuration file for the OSM import produced by imposm3.
- mapbox.json - a [mapbox-gl style](https://www.mapbox.com/mapbox-gl-js/style-spec/) config used for client side rendering.

## Dependencies

- Postgres server with [PostGIS](http://www.postgis.net) enabled.
- imposm3 ([download](https://imposm.org/static/rel/) - linux only)
- tegola ([download](https://github.com/terranodo/tegola/releases))

## Download the OSM planent database in PBF format

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