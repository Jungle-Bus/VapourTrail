
## Configuration for dump-tiles task
#static_url=https://frodrigo.github.io/VapourTrail/web/tiles
static_url=http://localhost:8080/tiles


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
	@echo ""
	@echo "Use URL: $(static_url)"
	# init directory
	rm -fr static
	mkdir static
	# copy web files
	cp -r web/* static/
	# copy dumped tiles
	cp -r docker/trex_cache/ static/tiles
	find static/tiles -type d -empty -delete
	find static/tiles -name "*.pbf" -exec mv {} {}.gz \;
	find static/tiles -name "*.pbf.gz" -exec gzip -d {} \;
	# use static_url instead of t_rex server
	sed -i -e 's="url": "http://0.0.0.0:6767/vapour_trail.json"="url": "$(static_url)/vapour_trail.json"=' static/vapour-style.json
	sed -i -e 's="http://example.com/tiles/vapour_trail/{z}/{x}/{y}.pbf"="$(static_url)/vapour_trail/{z}/{x}/{y}.pbf"=' static/tiles/vapour_trail.json
