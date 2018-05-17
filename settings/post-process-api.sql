-- Build JSON for each stops
DROP TABLE IF EXISTS a_stops;
CREATE TABLE a_stops AS
SELECT
  json_agg(json) AS json
FROM (
  SELECT
    row_to_json(t) AS json,
    osm_type,
    osm_id
  FROM (
    SELECT
      d_stops.osm_type,
      d_stops.osm_id,
      i_routes.osm_id AS rel_osm_id,
      i_routes.transport_mode,
      i_routes.network AS rel_network,
      i_routes.operator AS rel_operator,
      i_routes.ref AS rel_ref,
      i_routes.origin AS rel_origin,
      i_routes.destination AS rel_destination,
      i_routes.colour AS rel_colour,
      i_routes.name AS rel_name,
      d_routes_ways_ids.ways_ids AS ways_ids,
      d_routes_position_ids.positions_ids AS positions_ids
    FROM
      d_stops
      JOIN i_positions ON
        i_positions.member_type = d_stops.osm_type AND
        i_positions.member_osm_id = d_stops.osm_id
      JOIN i_routes ON
        i_routes.osm_id = i_positions.rel_osm_id
      JOIN d_routes_ways_ids ON
        d_routes_ways_ids.rel_osm_id = i_routes.osm_id
      JOIN d_routes_position_ids ON
        d_routes_position_ids.rel_osm_id = i_routes.osm_id
    ) AS t
  ) AS t
GROUP BY
  osm_type,
  osm_id
;


-- Build JSON for each route
DROP TABLE IF EXISTS a_routes;
CREATE TABLE a_routes AS
SELECT
  json_build_object(
    'type', 'FeatureCollection',
    'properties', json_build_object(
      'osm_id', rel_osm_id,
      'ref', rel_ref,
      'colour', rel_colour
    ),
    'features', json_agg(feature)
  ) AS json
FROM (
  SELECT
    i_routes.osm_id AS rel_osm_id,
    MAX(i_routes.ref) AS rel_ref,
    MAX(i_routes.colour) AS rel_colour,
    MAX(i_positions.member_index) AS index,
    json_build_object(
      'type', 'Feature',
      'properties', json_build_object(
        'name', MAX(i_stops.name),
        'other_routes', array_agg(DISTINCT hstore(ARRAY['osm_id', other_routes.osm_id::text, 'name', other_routes.name, 'ref', other_routes.ref::text, 'colour', other_routes.colour::text]))
      ),
      'geometry', ST_AsGeoJSON(ST_Transform(MAX(i_positions.geom), 4326))::json
    ) AS feature
  FROM
    i_routes
    JOIN i_positions ON
      i_positions.rel_osm_id = i_routes.osm_id
    LEFT JOIN i_stops ON
      i_stops.osm_type = i_positions.member_type AND
      i_stops.osm_id = i_positions.member_osm_id
    LEFT JOIN i_positions AS other_positions ON
      other_positions.member_type = i_positions.member_type AND
      other_positions.member_osm_id = i_positions.member_osm_id AND
      other_positions.rel_osm_id != i_routes.osm_id
    LEFT JOIN i_routes AS other_routes ON
      other_routes.osm_id = other_positions.rel_osm_id
  GROUP BY
    i_routes.osm_id,
    coalesce(i_stops.name, i_positions.member_type::text || '_' || i_positions.member_osm_id::text)
  ORDER BY
    rel_osm_id,
    index
  ) AS t
GROUP BY
  rel_osm_id,
  rel_ref,
  rel_colour
;
