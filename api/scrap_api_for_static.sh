#!/bin/bash

set -o pipefail
set -o nounset

mkdir static/api/routes/ -p
mkdir static/api/stops/


while read -r stop_id
do
    wget "http://localhost:8082/api/stops/$stop_id" -P ./static/api/stops
done < ./imposm/import/stops.txt

while read -r route_id
do
    wget "http://localhost:8082/api/routes/$route_id" -P ./static/api/routes
done < ./imposm/import/routes.txt
