-- requête pour construire la liste des parcours de chaque arrêt :
drop table if exists osm_stops;

select json_agg(routes_at_stop), osm_id into osm_stops from
	(select row_to_json(t) as routes_at_stop, osm_id from
		(select
			osm_bus_points.osm_id,
			osm_bus_route_members.rel_osm_id,
			osm_bus_route_members.transport_mode,
			osm_bus_route_members.rel_network ,
			osm_bus_route_members.rel_operator,
			osm_bus_route_members.rel_ref,
			osm_bus_route_members.rel_origin,
			osm_bus_route_members.rel_destination,
			osm_bus_route_members.rel_colour,
			osm_bus_route_members.rel_name
		from osm_bus_points
		join osm_bus_route_members on osm_bus_points.osm_id = osm_bus_route_members.member_osm_id
		--where osm_bus_points.osm_id = 25975014
		)
	as t)
as routes_at_stop_result
group by osm_id;

-- on ajoute une colonne dans la table initiale
alter table osm_bus_points add routes_at_stop character varying;

-- et on la remplit
update osm_bus_points set routes_at_stop =
     (select json_agg from osm_stops where osm_stops.osm_id = osm_bus_points.osm_id);


--- Add route "diameter" to osm_bus_route_members
CREATE TEMP TABLE tt_osm_bus_route_members_diameter AS
SELECT
  rel_osm_id,
  2 * sqrt(st_area(st_transform(ST_MinimumBoundingCircle(st_union(geometry)), 4326)::geography) / (3.14 )) AS diameter
FROM
  public.osm_bus_route_members
GROUP BY
  rel_osm_id
;

ALTER TABLE osm_bus_route_members ADD COLUMN diameter INTEGER;

UPDATE
  osm_bus_route_members
SET
  diameter = tt_osm_bus_route_members_diameter.diameter
FROM
  tt_osm_bus_route_members_diameter
WHERE
  tt_osm_bus_route_members_diameter.rel_osm_id = osm_bus_route_members.rel_osm_id
;

--- Add average stop distance on osm_bus_route_members and osm_bus_points
CREATE TEMP TABLE tt_osm_bus_route_members_avg_distance AS
SELECT
  rel_osm_id,
  avg(distance) AS avg_distance
FROM
(
SELECT
  rel_osm_id,
  ST_Distance(geometry::geography, (lag(geometry, 1, geometry) OVER (PARTITION BY rel_osm_id ORDER BY rel_osm_id, member_index))::geography) AS distance
FROM
  (SELECT rel_osm_id, member_index, ST_Transform(geometry, 4326) AS geometry FROM public.osm_bus_route_members WHERE member_role LIKE '%stop%') AS t
) AS t
WHERE
  distance > 10
GROUP BY
  rel_osm_id
;

ALTER TABLE osm_bus_route_members ADD COLUMN avg_distance INTEGER;

UPDATE
  osm_bus_route_members
SET
  avg_distance = tt_osm_bus_route_members_avg_distance.avg_distance
FROM
  tt_osm_bus_route_members_avg_distance
WHERE
  tt_osm_bus_route_members_avg_distance.rel_osm_id = osm_bus_route_members.rel_osm_id
;

ALTER TABLE osm_bus_points ADD COLUMN avg_distance INTEGER;

UPDATE
   osm_bus_points
SET
   avg_distance = osm_bus_route_members.avg_distance
FROM
  osm_bus_route_members
WHERE
  osm_bus_points.osm_id = osm_bus_route_members.member_osm_id
;

-- Deduplicate linstring
DROP TABLE IF EXISTS osm_bus_ways;
CREATE TABLE osm_bus_ways AS
SELECT
  rel_ref,
  diameter,
  (ST_Dump(geometry)).geom AS geometry
FROM
(
  SELECT
    rel_ref,
    max(diameter) AS diameter,
    ST_LineMerge(ST_Union(geometry)) AS geometry
  FROM
  (
    SELECT
      member_osm_id,
      string_agg(DISTINCT rel_ref, '  ') AS rel_ref,
      max(diameter) AS diameter,
      max(geometry) AS geometry
    FROM
      osm_bus_route_members
    WHERE
      member_type = 1 AND -- Way
      member_role NOT LIKE '%stop%'
    GROUP BY
      member_osm_id
  ) AS t
  GROUP BY
    rel_ref
) AS t
;

-- Deduplicate linstring
DROP TABLE IF EXISTS transport_bus_ways;
CREATE TABLE transport_bus_ways AS
SELECT
  rel_colour,
  rel_destination,
  rel_name,
  rel_network,
  rel_operator,
  rel_origin,
  rel_osm_id,
  rel_ref,
  transport_mode,
  (ST_Dump(geometry)).geom AS geometry
FROM
(
  SELECT
    rel_colour,
    rel_destination,
    rel_name,
    rel_network,
    rel_operator,
    rel_origin,
    rel_osm_id,
    rel_ref,
    transport_mode,
    ST_LineMerge(ST_Union(geometry)) AS geometry
  FROM
    osm_bus_route_members
  WHERE
    ST_GeometryType(geometry) = 'ST_LineString'
  GROUP BY
    rel_colour,
    rel_destination,
    rel_name,
    rel_network,
    rel_operator,
    rel_origin,
    rel_osm_id,
    rel_ref,
    transport_mode
) AS t
;
