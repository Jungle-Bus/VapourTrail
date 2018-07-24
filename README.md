# VapourTrail

VapourTrail is an interactive bus map made from OpenStreetMap data.

![demo](img/demo.gif)

## Schema

:construction::warning: This is a work in progress, the schema is not stable yet :warning::construction:

## Contribute

### Dependencies

* imposm3
* postgre / postgis
* t-rex
* docker / docker-compose
* python3 with flask and SQLAlchemy

### How to run

Put an .osm.pbf file into `docker/imposm/import` directory.

Run `make docker-importer` to import the data to the Postgres database.

The first run will perform several actions:

* download all the required base images,
* build and run the containers
* create the database
* import the osm.pbf file
* execute the post_process SQL scripts

Run `make up-d` to run the services (web and api) in detached mode.

The tiles rendered by t-rex are available at `http://localhost:6767/`.

The web front-end is available at `http://localhost:8082/vapour_trail.html`.

The API (used by the front-end) is available at `http://localhost:5000`. The endpoint used is `/route/<string:route_id>`.

**Troubleshooting**: If you don't see the name of the bus stops on the map after import or if the bus stop popups are empty, try to restart t-rex service: `docker-compose restart t-rex`

If you have performance issues, you may want to pre-generate the tiles before using the front : `make generate-tiles bbox=minlon,minlat,maxlon,maxlat`

### Deploy a static version

To get a static version (that can work without t-rex and postgres):

* import data: `make docker-importer`
* generate tiles for your area of interest: `make generate-tiles bbox=minlon,minlat,maxlon,maxlat`
* prepare static publication: `make prepare-static static_url=http://localhost/tile`
* you can now deploy and serve the `static` folder

### Style Edition

The background style is in `web/glstyle.json` while the foreground style is in `web/vapour-style.json`. Both can be edited manually or with style editor.

With the t-rex tiles server running locally you can upload `vapour-style.json` to the online [Maputnik Editor](http://editor.openmaptiles.org) and exported back.

## License

This project has been developed by the [Jungle Bus](http://junglebus.io/) team, a French non-profit organization dedicated to bus public transport in OpenStreetMap. Please reuse!

The code in this repository is under the MIT license.

This project relies on OpenStreetMap data so you need to credit the contributors. We propose the following wording:
    [Jungle Bus](http://junglebus.io/) [© OpenStreetMap contributors](http://www.openstreetmap.org/copyright)

If you value this work, show your support by donating to the [OSM French local chapter](http://openstreetmap.fr).

## Name

    🎼 There's a monkey in the jungle watching a vapour trail 🎶

    🎵 Caught up in the conflict between his brain and his tail 🎜
