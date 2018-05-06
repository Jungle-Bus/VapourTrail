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
  ((SELECT 0 AS osm_type, * FROM osm_nodes) UNION (SELECT 1 AS osm_type, * FROM osm_ways)) AS t
;

DROP TABLE osm_nodes;
DROP TABLE osm_ways;


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


-- When no bus stop present for a i_positions, add the clostest one
INSERT INTO i_positions
SELECT DISTINCT ON(i_positions.rel_osm_id, i_positions.member_type, i_positions.member_osm_id)
  i_positions.rel_osm_id,
  i_stops.osm_type AS member_type,
  i_stops.osm_id AS member_osm_id,
  ST_Centroid(i_stops.geom) AS geom
FROM (
  SELECT
    i_positions.*
  FROM
    i_positions
    LEFT JOIN (
      SELECT
        i_positions.rel_osm_id,
        i_stops.osm_type,
        i_stops.osm_id
      FROM
        i_positions
        JOIN osm_relation_members ON
          osm_relation_members.rel_osm_id = i_positions.rel_osm_id
        JOIN i_stops ON
          i_stops.osm_type = osm_relation_members.member_type AND
          i_stops.osm_id = osm_relation_members.member_osm_id AND
          ST_DistanceSphere(
            ST_Transform(i_positions.geom, 4326),
            ST_Transform(i_stops.geom, 4326)
          ) < 100
    ) AS no_stops ON
      no_stops.rel_osm_id = i_positions.rel_osm_id AND
      no_stops.osm_type = i_positions.member_type AND
      no_stops.osm_id = i_positions.member_osm_id
  WHERE
    no_stops.osm_id IS NULL
  ) AS i_positions
  JOIN i_stops ON
    ST_DistanceSphere(
      ST_Transform(i_positions.geom, 4326),
      ST_Transform(i_stops.geom, 4326)
    ) < 20
ORDER BY
  i_positions.rel_osm_id,
  i_positions.member_type,
  i_positions.member_osm_id,
  ST_DistanceSphere(
    ST_Transform(i_positions.geom, 4326),
    ST_Transform(i_stops.geom, 4326)
  )
;


-- Clean
DROP TABLE osm_relation_members;
