map.on('load', function() {

    map.addSource('route_members', {
        "type": 'vector',
        "id": "route_members",
        "maxzoom": 22,
        "minzoom": 0,
        "name": "route_members",
        "scheme": "xyz",
        "tiles": ["http://0.0.0.0:6767/route_members/{z}/{x}/{y}.pbf"],
        // that's a little hack to add the attribution, that is not set in the t-rex tilejson
        "attribution": "Jungle Bus"
    });
    map.addSource('route_stop_members', {
        "type": 'vector',
        "url": "http://0.0.0.0:6767/route_stop_members.json"
    });
    map.addSource('transport_points', {
        "type": 'vector',
        "url": "http://0.0.0.0:6767/transport_points.json"
    });

    map.addLayer({
        "id": "line-intercity",
        "type": "line",
        "metadata": {},
        "source": "route_members",
        "source-layer": "route_members",
        "paint": {
            "line-color": "#4898ff",
            "line-width": 2
        },
        "filter": [
            "all", [
                ">",
                "diameter",
                3000
            ]
        ]
    });
    map.addLayer({
        "id": "line-urban",
        "type": "line",
        "metadata": {},
        "source": "route_members",
        "source-layer": "route_members",
        "paint": {
            "line-color": "#4898ff",
            "line-width": 2
        },
        "filter": [
            "all", [
                "<=",
                "diameter",
                3000
            ]
        ],
        "minzoom": 12
    });
    map.addLayer({
        "id": "stop-label-intercity",
        "type": "symbol",
        "source": "transport_points",
        "source-layer": "transport_points",
        "layout": {
            "icon-image": "bus_11",
            "text-anchor": "left",
            "text-field": "{name}",
            "text-font": [
                "Klokantech Noto Sans Italic"
            ],
            "text-max-width": 5,
            "text-offset": [
                1,
                0
            ],
            "text-padding": 2,
            "text-size": {
                "stops": [
                    [
                        12.99,
                        0
                    ],
                    [
                        13,
                        12
                    ],
                    [
                        24,
                        16
                    ]
                ]
            },
            "visibility": "visible",
            "text-allow-overlap": false,
            "text-ignore-placement": false,
            "text-optional": true,
            "text-justify": "left",
            "icon-allow-overlap": false,
            "icon-ignore-placement": false,
            "icon-optional": false
        },
        "paint": {
            "text-color": "#4898ff",
            "text-halo-blur": 0.5,
            "text-halo-color": "#ffffff",
            "text-halo-width": 1.5,
            "icon-color": "rgba(27, 65, 189, 1)"
        },
        "maxzoom": 24,
        "minzoom": 0,
        "filter": [
            "all", [
                ">",
                "avg_distance",
                2000
            ]
        ]
    });
    map.addLayer({
        "id": "stop-label-urban",
        "type": "symbol",
        "source": "transport_points",
        "source-layer": "transport_points",
        "layout": {
            "icon-image": "bus_11",
            "text-anchor": "left",
            "text-field": "{name}",
            "text-font": [
                "Klokantech Noto Sans Italic"
            ],
            "text-max-width": 5,
            "text-offset": [
                1,
                0
            ],
            "text-padding": 2,
            "text-size": {
                "stops": [
                    [
                        12.99,
                        0
                    ],
                    [
                        13,
                        12
                    ],
                    [
                        24,
                        16
                    ]
                ]
            },
            "visibility": "visible",
            "text-allow-overlap": false,
            "text-ignore-placement": false,
            "text-optional": true,
            "text-justify": "left",
            "icon-allow-overlap": false,
            "icon-ignore-placement": false,
            "icon-optional": false
        },
        "paint": {
            "text-color": "#4898ff",
            "text-halo-blur": 0.5,
            "text-halo-color": "#ffffff",
            "text-halo-width": 1.5,
            "icon-color": "rgba(27, 65, 189, 1)"
        },
        "maxzoom": 24,
        "minzoom": 12,
        "filter": [
            "all", [
                "<=",
                "avg_distance",
                2000
            ]
        ]
    });
    //pre-add layers with a dumb filter
    map.addLayer({
        "id": "transport_ways_filtered_outline",
        "type": "line",
        "metadata": {},
        "source": "route_members",
        "source-layer": "route_members",
        "filter": ["==", "rel_osm_id", "dumb_filter"],
        "paint": {
            "line-color": "#000",
            "line-width": 6
        }
    });
    map.addLayer({
        "id": "transport_ways_filtered",
        "type": "line",
        "metadata": {},
        "source": "route_members",
        "source-layer": "route_members",
        "filter": ["==", "rel_osm_id", "dumb_filter"],
        "paint": {
            "line-color": {
                "type": "identity",
                "property": "rel_colour"
            },
            "line-width": 4
        }
    });
    map.addLayer({
        "id": "transport_points_filtered",
        "type": "circle",
        "metadata": {},
        "source": "route_stop_members",
        "source-layer": "route_stop_members",
        "filter": ["==", "rel_osm_id", "dumb_filter"],
        "paint": {
            "circle-color": {
                "type": "identity",
                "property": "rel_colour"
            },
            "circle-opacity": 0.5,
            "circle-radius": {
                "base": 1,
                "stops": [
                    [
                        12, 12
                    ],
                    [
                        18, 8
                    ]
                ]
            }
        }
    })
})
