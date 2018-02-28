run-postgres:
	docker-compose run -d postgres  
	sleep 45

run-t-rex:
	docker-compose run -d t-rex 

import-osm:
	docker-compose run importer 
	
import-post-process:
	docker-compose run importer /usr/src/app/psql.sh -f /mapping/post-process.sql

all: run-postgres import-osm import-post-process run-t-rex 
