# VapourTrail
VapourTrail is a vector tile schema for OpenStreetMap bus data.

It allows to create interactive map with buses without using Overpass API (because Overpass is great but we need to learn to stop relying on it).

## Use cases

Show bus stops

Show roads where buses go

Show properties of a bus stop (shelter, etc)

Show bus routes serving a bus stop

Show all tracks and stops for a selected bus route

Show properties and list of stops for a selected bus route

Show all routes for a bus line

![where do the bus go](img/all_routes_and_stops.png)

![where do the bus go](img/all_route_and_stop.png)

![stop detail](img/stop_detail.png)

![route detail](img/route_detail.png)

## Schema
    TODO

## Contribute
### Dependencies
* imposm3
* t-rex
* docker / docker-compose

### How to run
run `make all` to import data and launch tile server (t-rex).

## License

This project has been developed by the [Jungle Bus](http://junglebus.io/) team, a French non-profit organization dedicated to bus public transport in OpenStreetMap. Please reuse !

The code in this repository is under the MIT license.

This project relies on OpenStreetMap data so you need to credit the contributors. We propose the following wording :
    [Jungle Bus](http://junglebus.io/) [© OpenStreetMap contributors](http://www.openstreetmap.org/copyright)

If you value this work, show your support by donating to the [OSM French local chapter](http://openstreetmap.fr).

## Name
    🎼 There's a monkey in the jungle watching a vapour trail 🎶

    🎵 Caught up in the conflict between his brain and his tail 🎜
