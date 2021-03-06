#!/bin/bash
set -o errexit
set -o pipefail
set -o nounset

# waiting for the DB server
RETRIES=40
export PGPASSWORD=$POSTGRES_PASSWORD
psql -h $POSTGRES_HOST -U $POSTGRES_USER -d $POSTGRES_DB -c "select 1"
until psql -h $POSTGRES_HOST -U $POSTGRES_USER -d $POSTGRES_DB -c "select 1" > /dev/null 2>&1 || [ $RETRIES -eq 0 ]; do
  echo "Waiting for postgres server, $((RETRIES--)) remaining attempts..."
  psql -h $POSTGRES_HOST -U $POSTGRES_USER -d $POSTGRES_DB -c "select 1"
  sleep 1
done

echo "Importing Data in DB (import schema)"
readonly PG_CONNECT="postgis://$POSTGRES_USER:$POSTGRES_PASSWORD@$POSTGRES_HOST:$POSTGRES_PORT/$POSTGRES_DB"
readonly DIFF_MODE=false
# readonly DIFF_MODE=${DIFF_MODE:-true}


function import_pbf() {
    local pbf_file="$1"
    local diff_flag=""
    if [ "$DIFF_MODE" = true ]; then
        diff_flag="-diff"
        echo "Importing in diff mode"
    else
        echo "Importing in normal mode"
    fi

    imposm3 import \
        -connection "$PG_CONNECT" \
        -mapping "$MAPPING_YAML" \
        -overwritecache \
        -diffdir "$DIFF_DIR" \
        -cachedir "$IMPOSM_CACHE_DIR" \
        -read "$pbf_file" \
        -write $diff_flag
}

function import_osm_with_first_pbf() {
    if [ "$(ls -A $IMPORT_DIR/*.pbf 2> /dev/null)" ]; then
        local pbf_file
        for pbf_file in "$IMPORT_DIR"/*.pbf; do
			import_pbf "$pbf_file"
            break
        done
    else
        echo "No PBF files for import found."
        echo "Please check that the imput folder is containing OSM PBF files."
        exit 404
    fi
}

import_osm_with_first_pbf

# /usr/src/app/psql.sh -c "CREATE EXTENSION postgis SCHEMA import;"

echo "Executing post-process script (part 1/2)"
/usr/src/app/psql.sh -f /mapping/post-process-internal.sql
echo "Executing post-process script (part 2/2)"
/usr/src/app/psql.sh -f /mapping/post-process-display.sql


echo "Data publication (rotating tables in schemas)"
# This command only move tables declared in mapping file, so it can't be used
# imposm3 import \
#     -connection "$PG_CONNECT" \
#     -mapping "$MAPPING_YAML" \
#     -deployproduction
# Using a SQL rotation instead
/usr/src/app/psql.sh -f /mapping/helpers.sql
/usr/src/app/psql.sh -c "select publish_data();";
