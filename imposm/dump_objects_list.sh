#!/bin/bash
set -o errexit
set -o pipefail
set -o nounset


# test
export PGPASSWORD=$POSTGRES_PASSWORD

psql -h $POSTGRES_HOST -U $POSTGRES_USER -d $POSTGRES_DB -At -c "SELECT osm_id FROM d_stops" > /import/stops.txt

psql -h $POSTGRES_HOST -U $POSTGRES_USER -d $POSTGRES_DB -At -c "SELECT osm_id FROM d_routes" > /import/routes.txt
