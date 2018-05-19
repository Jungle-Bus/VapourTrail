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
	docker-compose restart t-rex
