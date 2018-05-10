var osm_img = "<img src='img/osm.svg' heigth='20px' width='20px' />"
var bus_img = "<img src='img/bus.svg' heigth='20px' width='20px' />"
var wheelchair_img = "<img src='img/wheelchair.svg' heigth='20px' width='20px' />"
var shelter_img = "<img src='img/shelter.svg' heigth='20px' width='20px' />"
var tactile_img = "<img src='img/tactile.svg' heigth='20px' width='20px' />"
var bench_img = "<img src='img/bench.svg' heigth='20px' width='20px' />"
var departures_img = "<img src='img/departures.svg' heigth='20px' width='20px' />"

var map = new mapboxgl.Map({
    container: 'map',
    style: 'glstyle.json',
    center: [
        1.8659, 46.1662
    ],
    zoom: 11.952145030855498,
    hash: true
});
map.on('load', function() {

    map.on('mouseenter', 'stops-icon', function() {
        map.getCanvas().style.cursor = 'pointer';
    });
    map.on('mouseleave', 'stops-icon', function() {
        map.getCanvas().style.cursor = '';
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


async function filter_on_one_route(route) {
    var ways_ids = route['ways_ids'];
    var positions_ids = route['positions_ids'];
    map.setFilter('routes_ways_filtered_outline', ["in", "id"].concat(ways_ids));
    map.setFilter('routes_ways_filtered', ["in", "id"].concat(ways_ids));
    map.setFilter('routes_points_filtered', ["in", "id"].concat(positions_ids));
    map.setPaintProperty('routes_ways_filtered', "line-color", route['rel_colour'] || 'grey')
    map.setPaintProperty('routes_points_filtered', "circle-color", route['rel_colour'] || 'grey')
    var html = `<div class='bus_box_div'>
                <span class='bus_box' style='border-bottom-color: ${route['rel_colour'] || "grey"};' >
                    <span>🚍</span>
                    <span>${route['rel_ref'] || '??'}</span>
                </span>
                &nbsp; ${route['rel_name']}
            </div>`
    html += `De <b>${route['rel_origin'] || '??'}</b> vers <b>${route['rel_destination'] || '??'}</b>`;
    if (route.hasOwnProperty('rel_via')) {
        html += `via <b>${route['rel_via'] || '??'}</b>`;
    }
    html += `<br>Réseau ${route['rel_network'] || '??'}`;
    html += `<br>Transporteur : ${route['rel_operator'] || '??'}`
    html += `<br><a href='#' onclick='reset_filters_and_show_all_lines()'>Masquer la ligne</a> <br/>`

    wait = `<br>...<br>`
    caisson.add_content(html + wait);

    try {
        const stop_list_url = "http://www.mocky.io/v2/5af49b4b55000067007a539a" //TODO, use the api here
        var stop_list_response = await fetch(stop_list_url);
        var stop_list_data = await stop_list_response.json();

        thermo = create_stop_list_for_a_route(stop_list_data['stop_list'], route['rel_colour'])
        caisson.add_content(html + thermo)

    } catch (err) {
        console.log("erreur en récupérant la liste des arrêts : " + err)
        caisson.add_content(html)
    }
};

function create_stop_list_for_a_route(stop_list, route_colour) {
    var route_colour = route_colour || 'grey';
    var inner_html = '<div class="stop_list">'
    for (const stop of stop_list) {
        if (stop != stop_list[stop_list.length - 1]) {
            inner_html += `<div class="stop_item" style="border-left-color:${route_colour};">`;
        } else { // remove the border so the stop list stops on a dot
            inner_html += `<div class="stop_item" style="border-left-color:#FFF;">`;
        }

        inner_html += `
          <span class="stop_dot" style="border-color:${route_colour};"></span>
          <div class="stop_name">${stop['name'] || '??'}</div>
          <div class="stop_shields">
          `
        for (const shield of stop['shield_list']) {
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

    inner_html += '</div>'
    return inner_html
}

function reset_filters_and_show_all_lines() {
    map.setFilter('routes_ways_filtered_outline', ["==", "rel_osm_id", "dumb_filter_again"]);
    map.setFilter('routes_ways_filtered', ["==", "rel_osm_id", "dumb_filter_again"]);
    map.setFilter('routes_points_filtered', ["==", "rel_osm_id", "dumb_filter_again"]);
    caisson.remove()
}
