# VapourTrail

VapourTrail is an interactive bus map made from OpenStreetMap data.

![demo](demo.gif)

VapourTrail aims to be a large scale or local solution for visualizing bus lines based on OpenStreetMap data composed of:
* an interactive map with a schematic bus route display
* an API for bus routes
* a tileset of vector tiles

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

Put an .osm.pbf file into `imposm/import/` directory.

Run `make run` to run the services (web, api, tiles and database) in detached mode.
Run `make data-update` to import or update the data to the Postgres database.

The tiles rendered by t-rex are available at `http://localhost:6767/`.

The web front-end is available at `http://localhost:8082/vapour_trail.html`.

The API (used by the front-end) is available at `http://localhost:5000`. The endpoint used is `/route/<string:route_id>`.

**Troubleshooting**:

If you have performance issues, you may want to pre-generate the tiles before using the front : `make generate-tiles bbox=minlon,minlat,maxlon,maxlat`

### Deploy a static version

To get a static version (that can work without t-rex and postgres):

* import data: `make docker-importer`
* generate tiles for your area of interest: `make generate-tiles bbox=minlon,minlat,maxlon,maxlat`
* prepare static publication: `make prepare-static static_url=http://localhost/tile`
* you can now deploy and serve the `static` folder

### Style Edition

The displayed map used bus vector tiles served by the t-rex server and [Jawg vector tiles](https://jawg.io) with a custom theme for the background style.

While the t-rex tiles server is running you can upload `glstyle.json` to the online [Maputnik Editor](http://editor.openmaptiles.org), make your changes and export it back to the project.

## License

This project has been developed by the [Jungle Bus](http://junglebus.io/) team, a French non-profit organization dedicated to bus public transport in OpenStreetMap. Please reuse!

The code in this repository is under the MIT license.

This project relies on OpenStreetMap data so you need to credit the contributors. We propose the following wording:
    [Jungle Bus](http://junglebus.io/) [© OpenStreetMap contributors](http://www.openstreetmap.org/copyright)

If you value this work, show your support by donating to the [OSM French local chapter](http://openstreetmap.fr).

## Name

    🎼 There's a monkey in the jungle watching a vapour trail 🎶

    🎵 Caught up in the conflict between his brain and his tail 🎜
