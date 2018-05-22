
all: up

up:
	docker-compose up web

up-d:
	docker-compose up -d web

down:
	docker-compose down

help:
	@echo VapourTrail https://github.com/Jungle-Bus/VapourTrail

docker-postgres:
	docker-compose restart postgres

docker-t-rex:
	docker-compose restart t-rex

docker-web:
	docker-compose restart web

docker-importer:
	docker-compose run --rm importer
	chmod a+rw docker/trex_cache

test:
	./scripts/test_on_monaco.sh

generate-tiles:
	./scripts/generate_all_tiles.sh

prepare-static:
	./scripts/prepare_static.sh
