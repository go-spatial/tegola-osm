# Tegola OSM

This repo houses instructions and configuration files to aid with standing up an Open Street Map export into a PostGIS enabled database that uses [tegola](https://github.com/terranodo/tegola) for creating and serving vector tiles.

## Repo files

- mapping.json - an [imposm3](https://github.com/omniscale/imposm3) configuration file.
- osm.toml - a [tegola](https://github.com/terranodo/tegola) configuration file.

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
./imposm3 import -connection postgis://username:password@host/database-name -mapping mapping.json
```

## Launch tegola 

```bash
./tegola -config=osm.toml
```