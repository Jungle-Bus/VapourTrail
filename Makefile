run:
	docker-compose up -d web

restart:
	docker-compose restart api
	docker-compose restart t-rex
	docker-compose restart web

update-data:
	docker-compose run --rm importer
	docker-compose run --rm --entrypoint 'rm -rf /srv/mvtcache/*' t-rex
	chmod a+rw t-rex/cache
	docker-compose restart api
	docker-compose restart t-rex
	docker-compose restart web

help:
	@echo VapourTrail https://github.com/Jungle-Bus/VapourTrail

imposm/import/monaco.osm.pbf:
	wget http://download.geofabrik.de/europe/monaco-latest.osm.pbf --no-verbose -O $@

#to get the bbox :  osmconvert --out-statistics imposm/import/monaco.osm.pbf | egrep 'lon |lat ' | cut -d ' ' -f 3 | tr '\n' ' ' | sed -E "s/([^ ]+) ([^ ]+) ([^ ]+) ([^ ]+)/\1,\3,\2,\4/"
test-monaco: run imposm/import/monaco.osm.pbf update-data
	make generate-tiles bbox=7.40701675415039,43.7229786663231,7.4437522888183585,43.7541091221655

test: test-monaco

generate-tiles:
	./t-rex/generate_all_tiles.sh

prepare-static:
	./web/prepare_static.sh
