-- Collect route segments (every way where a bus route goes)
DROP TABLE IF EXISTS d_ways;
CREATE TABLE d_ways AS
SELECT
  max_diameter,
  number_of_routes,
  rels_osm_id,
  (ST_Dump(geom)).geom AS geom
FROM (
  SELECT
    max_diameter,
    number_of_routes,
    ARRAY (SELECT id FROM unnest(rels_osm_id) AS t(id)) AS rels_osm_id,
    ST_LineMerge(ST_Union(geom)) AS geom
  FROM (
    SELECT
      max(i_routes.diameter) AS max_diameter,
      count(DISTINCT i_routes.osm_id) AS number_of_routes,
      array_agg(DISTINCT i_routes.osm_id) AS rels_osm_id,
      i_ways.geom
    FROM
      i_routes
      JOIN i_ways ON
        i_routes.osm_id = i_ways.rel_osm_id
    GROUP BY
      i_ways.geom
    ) AS t
  GROUP BY
    max_diameter,
    number_of_routes,
    rels_osm_id
  ) AS t
;
CREATE INDEX idx_d_ways_geom ON d_ways USING GIST(geom);
DROP SEQUENCE IF EXISTS d_ways_id_seq;
CREATE SEQUENCE d_ways_id_seq;
ALTER TABLE d_ways ADD COLUMN id integer NOT NULL DEFAULT nextval('d_ways_id_seq');

-- Compute the list of segments id for each bus route
DROP TABLE IF EXISTS d_routes_ways_ids;
CREATE TABLE d_routes_ways_ids AS
SELECT
  rel_osm_id,
  array_agg(id) AS ways_ids
FROM (
  SELECT
    id,
    unnest(rels_osm_id) AS rel_osm_id
  FROM
    d_ways
) AS t
GROUP BY
  rel_osm_id
;
ALTER TABLE d_ways DROP COLUMN rels_osm_id;


-- Collect stop positions for each route : take the stop_position or project the stop on the way
DROP TABLE IF EXISTS d_routes_position;
CREATE TABLE d_routes_position AS
SELECT
  array_agg(DISTINCT osm_id) AS rels_osm_id,
  geom
FROM (
  SELECT DISTINCT ON(
    i_routes.osm_id,
    coalesce(i_stops.name, i_positions.member_type::text || '_' || i_positions.member_osm_id::text)
    )

    i_routes.osm_id,
    ST_LineInterpolatePoint(i_ways.geom, ST_LineLocatePoint(i_ways.geom, i_positions.geom)) AS geom
  FROM
    i_routes
    JOIN i_ways ON
      i_routes.osm_id = i_ways.rel_osm_id
    JOIN i_positions ON
      i_routes.osm_id = i_positions.rel_osm_id
    LEFT JOIN i_stops ON
      i_positions.member_type = i_stops.osm_type AND
      i_positions.member_osm_id = i_stops.osm_id
  WHERE
    i_ways.geom && i_positions.geom AND
    ST_DistanceSphere(
      ST_Transform(i_positions.geom, 4326),
      ST_Transform(ST_LineInterpolatePoint(i_ways.geom, ST_LineLocatePoint(i_ways.geom, i_positions.geom)), 4326)
    ) < 10
  ORDER BY
    i_routes.osm_id,
    coalesce(i_stops.name, i_positions.member_type::text || '_' || i_positions.member_osm_id::text),
    ST_DistanceSphere(
      ST_Transform(i_positions.geom, 4326),
      ST_Transform(ST_LineInterpolatePoint(i_ways.geom, ST_LineLocatePoint(i_ways.geom, i_positions.geom)), 4326)
    )
  ) AS t
GROUP BY
  geom
;
CREATE INDEX idx_d_routes_position_geom ON d_routes_position USING GIST(geom);
DROP SEQUENCE IF EXISTS d_routes_position_id_seq;
CREATE SEQUENCE d_routes_position_id_seq;
ALTER TABLE d_routes_position ADD COLUMN id integer NOT NULL DEFAULT nextval('d_routes_position_id_seq');

-- Compute the list of stop positions id for each bus route
DROP TABLE IF EXISTS d_routes_position_ids;
CREATE TABLE d_routes_position_ids AS
SELECT
  rel_osm_id,
  array_agg(id) AS positions_ids
FROM (
  SELECT
    id,
    unnest(rels_osm_id) AS rel_osm_id
  FROM
    d_routes_position
) AS t
GROUP BY
  rel_osm_id
;
ALTER TABLE d_routes_position DROP COLUMN rels_osm_id;


-- Add bus routes info on bus stops
DROP TABLE IF EXISTS d_stops;
CREATE TABLE d_stops AS
SELECT
  *,
  NULL::int AS max_diameter,
  NULL::int AS max_avg_distance,
  NULL::int AS number_of_routes,
  NULL::text[][] AS routes_ref_colour
FROM
  i_stops
;
CREATE INDEX idx_d_stops_geom ON d_stops USING GIST(geom);


DROP TABLE IF EXISTS t_stops_routes;
CREATE TEMP TABLE t_stops_routes AS
SELECT
  d_stops.osm_type,
  d_stops.osm_id,
  max(i_routes.diameter) AS max_diameter,
  max(i_routes.avg_distance) AS max_avg_distance,
  count(*) AS number_of_routes,
  array_agg(DISTINCT array[i_routes.ref, i_routes.colour]) AS routes_ref_colour
FROM
  d_stops
  JOIN i_positions ON
    i_positions.member_type = d_stops.osm_type AND
    i_positions.member_osm_id = d_stops.osm_id
  JOIN i_routes ON
    i_routes.osm_id = i_positions.rel_osm_id
GROUP BY
  d_stops.osm_type,
  d_stops.osm_id
;

UPDATE
  d_stops
SET
  max_diameter = dt.max_diameter,
  max_avg_distance = dt.max_avg_distance,
  number_of_routes = dt.number_of_routes,
  routes_ref_colour = dt.routes_ref_colour
FROM
  t_stops_routes AS dt
WHERE
  dt.osm_type = d_stops.osm_type AND
  dt.osm_id = d_stops.osm_id
;

DROP TABLE t_stops_routes;


-- Compute stops shield
DROP TABLE IF EXISTS d_stops_shield;
CREATE TABLE d_stops_shield AS
SELECT
  osm_type,
  osm_id,
  i,
  routes_ref_colour[i][1] AS ref,
  CASE WHEN routes_ref_colour[i][2] IS NULL OR routes_ref_colour[i][2] = '' THEN 'gray' ELSE routes_ref_colour[i][2] END AS colour,
  geom
FROM (
  SELECT
    generate_subscripts(routes_ref_colour, 1) as i,
    *
  FROM
    d_stops
  ) AS t
;
ALTER TABLE d_stops DROP COLUMN routes_ref_colour;


-- Collect stations
DROP TABLE IF EXISTS d_stations;
CREATE TABLE d_stations AS
SELECT
  name,
  ST_GeometryType(geom) = 'ST_Polygon' AS has_polygon,
  ST_Centroid(geom) AS geom
FROM
  i_stations
;
CREATE INDEX idx_d_stations_geom ON d_stations USING GIST(geom);

DROP TABLE IF EXISTS d_stations_area;
CREATE TABLE d_stations_area AS
SELECT
  name,
  geom
FROM
  i_stations
WHERE
  ST_GeometryType(geom) = 'ST_Polygon'
;
CREATE INDEX idx_d_stations_area_geom ON d_stations_area USING GIST(geom);


-- Hack to inject JSON into vtiles, need an API to remove this.
DROP TABLE IF EXISTS t_stops_json;
CREATE TEMP TABLE t_stops_json AS
SELECT
  json_agg(routes_at_stop) AS json,
  osm_id
FROM (
  SELECT
    row_to_json(t) AS routes_at_stop,
    osm_id
  FROM (
    SELECT
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
  osm_id
;

ALTER TABLE d_stops ADD COLUMN routes_at_stop VARCHAR;
UPDATE
  d_stops
SET
  routes_at_stop = t_stops_json.json
FROM
  t_stops_json
WHERE
  d_stops.osm_id = t_stops_json.osm_id
;

DROP TABLE t_stops_json;

