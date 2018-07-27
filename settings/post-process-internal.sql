-- Build routes meta data
DROP TABLE IF EXISTS i_routes;
CREATE TABLE i_routes AS
SELECT
  *,
  NULL::integer AS diameter,
  NULL::integer AS avg_distance
FROM
  osm_relations_route
;
DROP TABLE osm_relations_route;


DROP TABLE IF EXISTS t_routes_avg_distance_diameter;
CREATE TEMP TABLE t_routes_avg_distance_diameter AS
SELECT
  rel_osm_id,
  avg(distance) AS avg_distance,
  2 * sqrt(st_area(ST_MinimumBoundingCircle(st_union(geom))::geography) / pi()) AS diameter
FROM (
  SELECT
    rel_osm_id,
    ST_DistanceSpheroid(geom, (lag(geom, 1, geom) OVER (PARTITION BY rel_osm_id ORDER BY rel_osm_id, member_index)), 'SPHEROID["WGS 84",6378137,298.257223563]') AS distance,
    geom
  FROM (
    SELECT
      rel_osm_id,
      member_index,
      ST_Transform(geom, 4326) AS geom
    FROM
      osm_relation_members_route
    WHERE
      osm_relation_members_route.member_role LIKE '%stop%'
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
CREATE TABLE i_stops AS ((
  SELECT
    0 AS osm_type,
    osm_id,
    id,
    name,
    has_shelter,
    has_bench,
    has_tactile_paving,
    has_departures_board,
    is_wheelchair_ok,
    local_ref,
    geom,
    ST_Transform(ST_Buffer(ST_Transform(geom, 4326)::geography, 200)::geometry, 3857) AS geom_buff
  FROM
    osm_nodes_bus_stop
) UNION (
  SELECT
    1 AS osm_type,
    osm_id,
    id,
    name,
    has_shelter,
    has_bench,
    has_tactile_paving,
    has_departures_board,
    is_wheelchair_ok,
    local_ref,
    ST_Centroid(geom) AS geom,
    ST_Transform(ST_Buffer(ST_Transform(geom, 4326)::geography, 200)::geometry, 3857) AS geom_buff
  FROM
    osm_ways_bus_stop
));

DROP TABLE IF EXISTS i_stops_cluster;
CREATE TABLE i_stops_cluster AS
SELECT
  array_agg(osm_type::text || '_' || osm_id::text) AS osm_type_id,
  array_agg(i_stops.osm_type) AS osm_type,
  array_agg(i_stops.osm_id) AS osm_id,
  i_stops.name AS name,
  ST_Centroid(ST_Collect(i_stops.geom)) AS geom
FROM (
  SELECT
    name,
    num,
    ST_Union(geom_buff) AS geom_buff_cluster
  FROM (
    SELECT
      name,
      row_number() OVER() as num,
      (ST_Dump(geom_buff_cluster)).geom AS geom_buff
    FROM (
      SELECT
        CASE WHEN name != '' THEN name ELSE osm_type::text || '_' || osm_id::text END AS name,
        ST_SetSRID(unnest(ST_ClusterIntersecting(geom_buff)), 3857) AS geom_buff_cluster
      FROM
        i_stops
      GROUP BY
        CASE WHEN name != '' THEN name ELSE osm_type::text || '_' || osm_id::text END
      ) AS t
    ) AS t
  GROUP BY
    name,
    num
  ) AS t
  JOIN i_stops ON
    CASE WHEN i_stops.name != '' THEN i_stops.name ELSE i_stops.osm_type::text || '_' || i_stops.osm_id::text END = t.name AND
    ST_Contains(t.geom_buff_cluster, i_stops.geom)
GROUP BY
  i_stops.name,
  t.num
;

ALTER TABLE i_stops DROP COLUMN geom_buff;

DROP TABLE osm_nodes_bus_stop;
DROP TABLE osm_ways_bus_stop;


-- Merge osm nodes and ways about stations
DROP TABLE IF EXISTS i_stations;
CREATE TABLE i_stations AS (
  (SELECT 0 AS osm_type, * FROM osm_nodes_bus_station)
  UNION
  (SELECT 1 AS osm_type, * FROM osm_ways_bus_station)
);

DROP TABLE osm_nodes_bus_station;
DROP TABLE osm_ways_bus_station;


-- Filter route ways from osm_relation_members_route
DROP TABLE IF EXISTS i_ways;
CREATE TABLE i_ways AS
SELECT
  rel_osm_id,
  member_index as index,
  geom
FROM
  osm_relation_members_route
WHERE
  member_type = 1 AND
  member_role NOT LIKE '%stop%' AND
  member_role NOT LIKE '%platform%'
;

-- Filter stops and platform from osm_relation_members_route
DROP TABLE IF EXISTS i_positions;
CREATE TABLE i_positions AS
SELECT
  rel_osm_id,
  member_type,
  member_osm_id,
  member_index,
  ST_Centroid(geom) AS geom
FROM
  osm_relation_members_route
WHERE
  member_type IN (0, 1) AND -- Ignore relation member
  (
    member_role LIKE '%stop%' OR
    member_role LIKE '%platform%'
  )
;


-- Clean
DROP TABLE osm_relation_members_route;
