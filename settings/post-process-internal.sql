-- Build routes meta data
DROP TABLE IF EXISTS i_routes;
CREATE TABLE i_routes AS
SELECT
  *,
  NULL::integer AS diameter,
  NULL::integer AS avg_distance
FROM
  osm_relations
;
DROP TABLE osm_relations;


DROP TABLE IF EXISTS t_routes_avg_distance_diameter;
CREATE TEMP TABLE t_routes_avg_distance_diameter AS
SELECT
  rel_osm_id,
  avg(distance) AS avg_distance,
  2 * sqrt(st_area(ST_MinimumBoundingCircle(st_union(geom))::geography) / pi()) AS diameter
FROM (
  SELECT
    rel_osm_id,
    ST_Distance(geom::geography, (lag(geom, 1, geom) OVER (PARTITION BY rel_osm_id ORDER BY rel_osm_id, member_index))::geography) AS distance,
    geom
  FROM (
    SELECT
      rel_osm_id,
      member_index,
      ST_Transform(geom, 4326) AS geom
    FROM
      osm_relation_members
    WHERE
      osm_relation_members.member_role LIKE '%stop%'
    ) AS t
  ) AS t
WHERE
  distance > 10
GROUP BY
  rel_osm_id
;

UPDATE
  i_routes
SET
  diameter = dt.diameter,
  avg_distance = dt.avg_distance
FROM
  t_routes_avg_distance_diameter AS dt
WHERE
  dt.rel_osm_id = i_routes.osm_id
;

DROP TABLE t_routes_avg_distance_diameter;


-- Merge osm nodes and ways about stops
DROP TABLE IF EXISTS i_stops;
CREATE TABLE i_stops AS
SELECT
  osm_type,
  osm_id,
  id,
  name,
  has_shelter,
  has_bench,
  has_tactile_paving,
  has_departures_board,
  is_wheelchair_ok,
  local_ref,
  ST_Centroid(geom) AS geom
FROM
  ((SELECT 0 AS osm_type, * FROM osm_nodes_bus_stop) UNION (SELECT 1 AS osm_type, * FROM osm_ways_bus_stop)) AS t
;

DROP TABLE osm_nodes_bus_stop;
DROP TABLE osm_ways_bus_stop;


-- Filter route ways from osm_relation_members
DROP TABLE IF EXISTS i_ways;
CREATE TABLE i_ways AS
SELECT
  rel_osm_id,
  geom
FROM
  osm_relation_members
WHERE
  member_type = 1 AND
  member_role NOT LIKE '%stop%' AND
  member_role NOT LIKE '%platform%'
;

-- Filter stops and platform from osm_relation_members
DROP TABLE IF EXISTS i_positions;
CREATE TABLE i_positions AS
SELECT
  rel_osm_id,
  member_type,
  member_osm_id,
  ST_Centroid(geom) AS geom
FROM
  osm_relation_members
WHERE
  member_role LIKE '%stop%' OR
  member_role LIKE '%platform%'
;


-- Clean
DROP TABLE osm_relation_members;
