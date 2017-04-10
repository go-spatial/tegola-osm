/*
	Adds indexes to OSM table columns to increase query performance per the tegola configuration.
*/

BEGIN;
	CREATE INDEX ON osm_roads_gen0 (type);
	CREATE INDEX ON osm_roads_gen1 (type);
	CREATE INDEX ON osm_roads (type);
	CREATE INDEX ON osm_admin (admin_level);
	CREATE INDEX ON osm_landusages_gen0 (type);
	CREATE INDEX ON osm_waterways (type);
	CREATE INDEX ON osm_waterways_gen0 (type);
	CREATE INDEX ON osm_waterways_gen1 (type);
	CREATE INDEX ON osm_waterareas (type);
	CREATE INDEX ON osm_waterareas_gen0 (type);	
	CREATE INDEX ON osm_waterareas_gen1 (type);
COMMIT;