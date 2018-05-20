#!/usr/bin/env bash

set -e
#set -x


#download Monaco data
wget http://download.geofabrik.de/europe/monaco-latest.osm.pbf --no-verbose
mv monaco-latest.osm.pbf docker/imposm/import/monaco.osm.pbf

#import data
make docker-importer

#generate tiles
osm_extent="7.40701675415039,43.7229786663231,7.4437522888183585,43.7541091221655"

    #to get the extent :  osmconvert --out-statistics docker/imposm/import/monaco-latest.osm.pbf | egrep 'lon |lat ' | cut -d ' ' -f 3 | tr '\n' ' ' | sed -E "s/([^ ]+) ([^ ]+) ([^ ]+) ([^ ]+)/\1,\3,\2,\4/"

docker-compose run --rm --entrypoint "t_rex generate --config /config/config.toml --overwrite true --extent=${osm_extent} --maxzoom 16 --minzoom 12" t-rex
