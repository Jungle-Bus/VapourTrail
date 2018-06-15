#!/usr/bin/env bash


if [ -z "${static_url}" ]; then
    echo "You need to add the url of your static server as a parameter"
    echo "   example: ${0##*/} static_url=http://localhost:8080/tiles"
    exit 1
fi

set -o errexit
set -o pipefail
set -o nounset
set -x

# init directory
rm -fr static
mkdir static

# copy web files
cp -r web/* static/

# copy dumped tiles
cp -r docker/trex_cache/ static/tiles
find static/tiles -name "*.pbf" -size `du -b static/tiles/vapour_trail/0/0/0.pbf | cut -f 1`c -delete
find static/tiles -type d -empty -delete
find static/tiles -name "*.pbf" -exec mv {} {}.gz \;
find static/tiles -name "*.pbf.gz" -exec gzip -d {} \;

# use static_url instead of t_rex server
sed -i -e "s=http://0.0.0.0:6767/vapour_trail.json=${static_url}/vapour_trail.json=g" static/vapour-style.json
sed -i -e "s=http://example.com/tiles/vapour_trail/{z}/{x}/{y}.pbf=${static_url}/vapour_trail/{z}/{x}/{y}.pbf=g" static/tiles/vapour_trail.json
