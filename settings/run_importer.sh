
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
