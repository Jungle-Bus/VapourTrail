var osm_img = "<img src='img/osm.svg' heigth='20px' width='20px' />"
var bus_img = "<img src='img/bus.svg' heigth='20px' width='20px' />"
var wheelchair_img = "<img src='img/wheelchair.svg' heigth='20px' width='20px' />"
var shelter_img = "<img src='img/shelter.svg' heigth='20px' width='20px' />"
var tactile_img = "<img src='img/tactile.svg' heigth='20px' width='20px' />"
var bench_img = "<img src='img/bench.svg' heigth='20px' width='20px' />"
var departures_img = "<img src='img/departures.svg' heigth='20px' width='20px' />"

const vapour_trail_api_base_url = "http://localhost:5000";

var map = new mapboxgl.Map({
    container: 'map',
    style: 'glstyle.json',
    center: [
        1.8659, 46.1662
    ],
    zoom: 13,
    hash: true
});
map.on('load', function() {

    map.on('mouseenter', 'stops-icon', function() {
        map.getCanvas().style.cursor = 'pointer';
    });
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

    function on_stop(e) {
        var feature = e.features[0];
        if (!feature.properties.routes_at_stop) {
            var routes_at_stop = []
        } else {
            var routes_at_stop = JSON.parse(feature.properties.routes_at_stop);
        }
        let html = ""
        html += `<h2> <a target="_blank" href="http://osm.org/node/${feature.properties.osm_id}">${bus_img}</a> `
        html += ` ${feature.properties.name || "pas de nom :("}</h2>`;

        html += "<p>"
        html += `${ (feature.properties.has_bench)
            ? bench_img
            : ""} `;
        html += `${ (feature.properties.has_shelter)
            ? shelter_img
            : ""} `;
        html += `${ (feature.properties.has_departures_board)
            ? departures_img
            : ""} `;
        html += `${ (feature.properties.is_wheelchair_ok)
            ? wheelchair_img
            : ""} `;
        html += `${ (feature.properties.has_tactile_paving)
            ? tactile_img
            : ""} `;
        html += "</p>"

        for (const route of routes_at_stop) {
            var route_in_json = JSON.stringify(route);
            var quote_escape_in_regexp = new RegExp("'", 'gi');
            var route_in_json = route_in_json.replace(quote_escape_in_regexp, '’');
            html += `<div class='bus_box_div'>
                        <span class='bus_box' style='border-bottom-color: ${route['rel_colour'] || "grey"};' >
                            [${route['rel_network'] || '??'}]
                            <span>🚍</span>
                            <span>${route['rel_ref'] || '??'}</span>
                        </span>
                      : ${route['rel_destination'] || '??'}
                      <a href='#' onclick='filter_on_one_route(${route_in_json})'>Voir la ligne</a> </br>
                    </div>`;
        }
        var popup = new mapboxgl.Popup({
            closeButton: false
        }).setLngLat(e.lngLat).setHTML(html).addTo(map);
    };

    map.on('click', 'stops-icon', on_stop);
});


function filter_on_one_route(route) {
    reset_filters_and_show_all_lines();

    var caisson_content = `
    <div id="route_info"></div>
    <div id="close_caisson_button"></div>
    <div id="stop_list" class="stop_list"></div>
    <div id="osm_attribution"></div>
    `
    caisson.add_content(caisson_content)
    var close_caisson_button = document.getElementById('close_caisson_button')
    close_caisson_button.innerHTML = `<a href='#' onclick='reset_filters_and_show_all_lines()'>Masquer la ligne</a>`;

    const route_id = route['rel_osm_id'];

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
    var inner_html = `<small>Ces informations proviennent d'<a href='https://OpenStreetMap.org' target='_blank'>OpenStreetMap</a>, la carte libre et collaborative.
    Rejoignez la communauté pour compléter ou corriger le détail de <a href='https://OpenStreetMap.org/relation/${osm_route_id}' target='_blank'>cette ligne</a> !</small>`;
    return inner_html
}

function create_route_medata(route_info) {
    var inner_html = `<div class='bus_box_div'>
                <span class='bus_box' style='border-bottom-color: ${route_info['colour'] || "grey"};' >
                    <span>🚍</span>
                    <span>${route_info['ref'] || '??'}</span>
                </span>
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
                <div class='bus_box_inline_div'>
                  <span class='bus_box' style='border-bottom-color: ${shield['colour'] || "grey"};' >
                    <span>🚍</span>
                  <span>${shield['ref'] || '??'}</span>
                  </span>
                </div>
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
 map.getSource('highlight_stop_source').setData(
     {
         "type": "Point",
         "coordinates": [stop_lon, stop_lat]
     }
 );
 map.setLayoutProperty('highlighted_stop', 'visibility', 'visible');
};
