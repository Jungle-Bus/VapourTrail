
RETRIES=40

export PGPASSWORD=$POSTGRES_PASSWORD

psql -h $POSTGRES_HOST -U $POSTGRES_USER -d $POSTGRES_DB -c "select 1"

until psql -h $POSTGRES_HOST -U $POSTGRES_USER -d $POSTGRES_DB -c "select 1" > /dev/null 2>&1 || [ $RETRIES -eq 0 ]; do
 echo "Waiting for postgres server, $((RETRIES--)) remaining attempts..."
 psql -h $POSTGRES_HOST -U $POSTGRES_USER -d $POSTGRES_DB -c "select 1"
 sleep 1
done

./import_osm.sh

echo "Executing post-process script"
/usr/src/app/psql.sh -f /mapping/post-process-internal.sql
/usr/src/app/psql.sh -f /mapping/post-process-display.sql
/usr/src/app/psql.sh -f /mapping/post-process-api.sql

#apt update && apt install -y jq

rm /mapping/api/*
psql -h $POSTGRES_HOST -U $POSTGRES_USER -d $POSTGRES_DB -At -c "SELECT * FROM a_stops" > /mapping/api/stops.json
cat /mapping/api/stops.json | jq -r '. | "\(.[0].osm_type)_\(.[0].osm_id)\t\(.)"' | awk -F\\t '{ print $2 > "/mapping/api/stops_" $1 ".json" }'
psql -h $POSTGRES_HOST -U $POSTGRES_USER -d $POSTGRES_DB -At -c "SELECT * FROM a_routes" > /mapping/api/routes.json
cat /mapping/api/routes.json | jq -r '. | "\(.properties.osm_id)\t\(.)"' | awk -F\\t '{ print $2 > "/mapping/api/routes_" $1 ".json" }'
