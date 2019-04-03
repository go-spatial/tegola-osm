# Deprecated Scripts

The scripts in this folder are deprecated and are not included in the docker container. They have been kept intact here with their instructions for backwards compatibility and to help with transitioning to the new docker compatible scripts.

## Import the OSM Land and Natural Earth dataset (requires gdal, Natural Earth can be skipped if you're only interested in OSM)

### Option 1: Embed Credentials
Update the database credentials inside of `natural_earth.sh` and `osm_land.sh`, then run each file: `./natural_earth.sh && ./osm_land.sh`. This will download the natural earth and osm land datasets and insert it into PostGIS under a database named `natural_earth` and `osm` respectively.

### Option 2: Create a dbcredentials.sh file
Create a `dbcredentials.sh` file which will be shared with the `osm_land` script.  This option is ideal for when the `natural_earth` and `osm` databases will reside on the same database server, and will use the same credentials. Ensure that the following variables are defined in your file:
```bash
DB_HOST="mydbhost"
DB_PORT="myport"
DB_USER="myuser"
DB_PW="mypassword"
```
Once you have configured the `dbcredentials.sh` file, run the scripts as above: `./natural_earth.sh && ./osm_land.sh`

### Option 3:
Create separate configuration files in the same pattern as the above `dbcredentials.sh` file and pass the path to the config file using the `-c` option.  This is ideal if you have two different servers for the databases. Ensure the file you create follows this format:
```bash
DB_NAME="mydb"
DB_HOST="mydbhost"
DB_PORT="myport"
DB_USER="myuser"
DB_PW="mypassword"
```
Once you have configured the files, run the scripts with the `-c` flag and provide the path to the credentials file, ie: `./natural_earth.sh -c natural_earth_creds.sh && ./osm_land.sh -c osm_creds.sh`

### Usage:
Both scripts support a `-v` flag for debugging.  `natural_earth.sh` also supports a `-d` flag, which will drop the existing natural earth database prior to import if set.  Since the `osm_land.sh` imports into a database shared with other data, it lacks this functionality.  Instead, only the relevent tables are dropped.