var osm_img = "<img src='img/osm.svg' heigth='20px' width='20px' />"
var bus_img = "<img src='img/bus.svg' heigth='20px' width='20px' />"
var wheelchair_img = "<img src='img/wheelchair.svg' heigth='20px' width='20px' />"
var shelter_img = "<img src='img/shelter.svg' heigth='20px' width='20px' />"
var tactile_img = "<img src='img/tactile.svg' heigth='20px' width='20px' />"
var bench_img = "<img src='img/bench.svg' heigth='20px' width='20px' />"
var shelter_bench_img = "<img src='img/shelter_bench.svg' heigth='20px' width='20px' />"
var departures_img = "<img src='img/departures.svg' heigth='20px' width='20px' />"

const vapour_trail_api_base_url = "/api";
const vapour_trail_tileserver_url = `${window.location.origin}/tiles/`;

var map = new mapboxgl.Map({
    container: 'map',
    style: 'glstyle.json',
    center: [
        1.8659, 46.1662
    ],
    zoom: 13,
    hash: true,
    transformRequest: (url, resourceType)=> {
    if(url.startsWith('http://t-rex:6767')) {
      return {
       url: url.replace('http://t-rex:6767/',  vapour_trail_tileserver_url)
     }
    } else if (url.startsWith('http://web:8082')) {
        console.log(url.replace('http://web:8082',  window.location.origin));
        return {
          url: url.replace('http://web:8082',  window.location.origin)
        }
    }
  }
});
map.on('load', function() {
    var popup = new mapboxgl.Popup({
        closeButton: false,
    });

    map.on('mouseenter', 'stops-icon', function() {
        map.getCanvas().style.cursor = 'pointer';
    });
    map.on('mouseenter', 'stops-icon', display_stop_popup);

    map.on('mouseleave', 'stops-icon', function() {
        map.getCanvas().style.cursor = '';
    });

    //new layer to highlight a stop in the stop_list
    map.addSource('highlight_stop_source', {
        "type": "geojson",
        "data": {
            "type": "Point",
            "coordinates": [1.8790708, 46.1740393]
        }
    });
    map.addLayer({
        "id": "highlighted_stop",
        "source": "highlight_stop_source",
        "type": "circle",
        "layout": {
            "visibility": "none",
        },
        'paint': {
            'circle-radius': {
                'base': 1.75,
                'stops': [
                    [12, 10],
                    [22, 200]
                ]
            },
            'circle-color': '#6e6b6b',
            'circle-opacity': 0.5
        }
    });

    function display_stop_popup(e) {
        if (map.getZoom() < 14) {
            return
        }
        var feature = e.features[0];
        const stop_id = feature.properties.osm_id;
        var stop_detail_url = vapour_trail_api_base_url + "/stops/" + feature.properties.osm_id;
        if (feature.properties.osm_type == "1") {
            stop_detail_url += "?osm_type=way"
        }
        fetch(stop_detail_url)
            .then(function(data) {
                return data.json()
            })
            .then(function(stop_data) {
                var html = ""
                html += `<h2>
                        <a target="_blank" href="http://osm.org/${stop_data.properties.osm_type}/${stop_data.properties.osm_id}">${bus_img}</a>
                        ${stop_data.properties.name || "pas de nom :("}
                    </h2>

                    <p>
                        ${ (stop_data.properties.has_shelter && stop_data.properties.has_bench) ? shelter_bench_img : ""}
                        ${ (stop_data.properties.has_shelter && !stop_data.properties.has_bench) ? shelter_img : ""}
                        ${ (!stop_data.properties.has_shelter && stop_data.properties.has_bench) ? bench_img : ""}
                        ${ (stop_data.properties.has_departures_board) ? departures_img : ""}
                        ${ (stop_data.properties.is_wheelchair_ok) ? wheelchair_img : ""}
                        ${ (stop_data.properties.has_tactile_paving) ? tactile_img : ""}
                    </p>`

                for (const route of stop_data.properties.routes_at_stop) {
                    const route_id = route['route_osm_id'];
                    html += `<transport-thumbnail
                        data-transport-network="${route['network'] || '??'}"
                        data-transport-mode="bus"
                        data-transport-line-code="${route['ref'] || '??'}"
                        data-transport-line-color="${route['colour'] || "grey"}"
                        data-transport-destination="${route['destination'] || '??'}">
                    </transport-thumbnail>
                    <a href='#' onclick='filter_on_one_route(${route_id});map.flyTo({center:[${stop_data.geometry.coordinates}]})'>Voir la ligne</a> </br>
                    `
                }

                html += `<div class="osm_attribution">${create_osm_attribution_for_the_stop(stop_data.properties.osm_id, stop_data.properties.osm_type)}</div>`

                popup.setLngLat(e.lngLat).setHTML(html).addTo(map);

            })
            .catch(function(error) {
                console.log("erreur en récupérant les informations sur l'arrêt : " + error)
            })

    };

    map.on('click', 'stops-icon', function(e) {
        if (map.getZoom() < 14) {
            map.flyTo({center: e.features[0].geometry.coordinates, zoom: 15});
        }
    });

});


function filter_on_one_route(route_id) {
    reset_filters_and_show_all_lines();

    var caisson_content = `
    <div id="close_caisson_button"></div>
    <div id="route_info"></div>
    <div id="stop_list" class="stop_list"></div>
    <div class="osm_attribution" id="osm_attribution"></div>
    `
    caisson.add_content(caisson_content)
    var close_caisson_button = document.getElementById('close_caisson_button')
    close_caisson_button.innerHTML = `<span onclick='reset_filters_and_show_all_lines()'>x</span>`;

    const stop_list_url = vapour_trail_api_base_url + "/routes/" + route_id;
    fetch(stop_list_url)
        .then(function(data) {
            return data.json()
        })
        .then(function(route_data) {
            var route_colour = route_data['route_info']['colour'] || 'grey';
            var route_info = document.getElementById('route_info');
            route_info.innerHTML = create_route_medata(route_data['route_info']);

            var thermo = create_stop_list_for_a_route(route_data['stop_list'], route_colour)
            var stop_list = document.getElementById('stop_list')
            stop_list.innerHTML = thermo;

            var osm_attribution = document.getElementById('osm_attribution')
            osm_attribution.innerHTML = create_osm_attribution_for_the_route(route_data['route_info']['osm_id']);


            var route_geom = route_data['geometry'];
            map.getSource('route_filter').setData(route_geom);
            map.setFilter('routes_ways_filtered', ["all"]);
            map.setFilter('routes_ways_filtered_outline', ["all"]);
            map.setPaintProperty('routes_ways_filtered', "line-color", route_colour)

            var positions_geom = route_data['stop_positions'];
            map.getSource('route_positions_filter').setData(positions_geom);
            map.setFilter('routes_points_filtered', ["all"]);
            map.setPaintProperty('routes_points_filtered', "circle-color", route_colour)

        })
        .catch(function(error) {
            console.log("erreur en récupérant les informations sur la ligne : " + error)
        })

};

function create_osm_attribution_for_the_route(osm_route_id) {
    return create_osm_attribution(osm_route_id, 'relation', 'cette ligne')
}

function create_osm_attribution_for_the_stop(osm_stop_id, osm_type) {
    return create_osm_attribution(osm_stop_id, osm_type, 'cet arrêt')
}

function create_osm_attribution(osm_object_id, osm_type, object_designation) {
    var inner_html = `<img src="img/osm.svg" alt="OpenStreetMap" width="55px" heigth="55px" style="float:left;"><small>Ces informations proviennent d'<a href='https://OpenStreetMap.org' target='_blank'>OpenStreetMap</a>, la carte libre et collaborative.
    Rejoignez la communauté pour compléter ou corriger le détail de <a href='https://OpenStreetMap.org/${osm_type}/${osm_object_id}' target='_blank'>${object_designation}</a> !</small>`;
    return inner_html
}

function create_route_medata(route_info) {
    var inner_html = `<div class='bus_box_div'>
                <transport-thumbnail
                    data-transport-mode="bus"
                    data-transport-line-code="${route_info['ref'] || '??'}"
                    data-transport-line-color="${route_info['colour'] || "grey"}">
                </transport-thumbnail>
                &nbsp; ${route_info['name']}
            </div>`;
    inner_html += `De <b>${route_info['origin'] || '??'}</b> vers <b>${route_info['destination'] || '??'}</b>`;
    if (route_info.hasOwnProperty('via')) {
        inner_html += `via <b>${route_info['via'] || '??'}</b>`;
    };
    inner_html += `<br>Réseau ${route_info['network'] || '??'}`;
    inner_html += `<br>Transporteur : ${route_info['operator'] || '??'}`;
    return inner_html;
}

function create_stop_list_for_a_route(stop_list, route_colour) {
    var route_colour = route_colour || 'grey';
    var inner_html = ''
    for (const stop of stop_list) {
        if (stop != stop_list[stop_list.length - 1]) {
            var border_color = route_colour;
        } else { // remove the border so the stop list stops on a dot
            var border_color = "#FFF";
        }

        inner_html += `<div class="stop_item" style="border-left-color:${border_color};"
                            onmouseover="highlight_one_stop(${stop['lon']}, ${stop['lat']})"
                            onclick="map.flyTo({center: [${stop['lon']}, ${stop['lat']}]});">`;

        inner_html += `
          <span class="stop_dot" style="border-color:${route_colour};"></span>
          <div class="stop_name">${stop['name'] || '??'}</div>
          <div class="stop_shields">
          `
        for (const shield of stop['shields']) {
            inner_html += `
                <transport-thumbnail class="bus_box_inline_div"
                    data-transport-mode="bus"
                    data-transport-line-code="${shield['ref'] || '??'}"
                    data-transport-line-color="${shield['colour'] || "grey"}">
                </transport-thumbnail>
                `
        }
        inner_html += `
          </div>
        </div>
        `
    }

    return inner_html
};

function reset_filters_and_show_all_lines() {
    map.setFilter('routes_ways_filtered_outline', ["==", "rel_osm_id", "dumb_filter_again"]);
    map.setFilter('routes_ways_filtered', ["==", "rel_osm_id", "dumb_filter_again"]);
    map.setFilter('routes_points_filtered', ["==", "rel_osm_id", "dumb_filter_again"]);
    caisson.remove()
};

function highlight_one_stop(stop_lon, stop_lat) {
    map.getSource('highlight_stop_source').setData({
        "type": "Point",
        "coordinates": [stop_lon, stop_lat]
    });
    map.setLayoutProperty('highlighted_stop', 'visibility', 'visible');
};
