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


---
CREATE TEMP TABLE tt_osm_bus_route_members_area_cirlce_size AS
SELECT
  rel_osm_id,
  st_area(st_transform(ST_MinimumBoundingCircle(st_union(geometry)), 4326)::geography) AS area_cirlce_size
FROM
  public.osm_bus_route_members
GROUP BY
  rel_osm_id
;

ALTER TABLE osm_bus_route_members ADD COLUMN area_cirlce_size INTEGER;

UPDATE
  osm_bus_route_members SET area_cirlce_size = tt_osm_bus_route_members_area_cirlce_size.area_cirlce_size
FROM
  tt_osm_bus_route_members_area_cirlce_size
WHERE
  tt_osm_bus_route_members_area_cirlce_size.rel_osm_id = osm_bus_route_members.rel_osm_id
;

---
CREATE TEMP TABLE tt_osm_bus_points_area_cirlce_size AS
SELECT
   osm_bus_points.osm_id,
   max(osm_bus_route_members.area_cirlce_size) AS area_cirlce_size
FROM
   osm_bus_points
   JOIN osm_bus_route_members ON osm_bus_points.osm_id = osm_bus_route_members.member_osm_id
 GROUP BY
   osm_bus_points.osm_id
;

ALTER TABLE osm_bus_points ADD COLUMN area_cirlce_size INTEGER;

UPDATE
   osm_bus_points
SET
   area_cirlce_size = tt_osm_bus_points_area_cirlce_size.area_cirlce_size
FROM
   tt_osm_bus_points_area_cirlce_size
WHERE
   tt_osm_bus_points_area_cirlce_size.osm_id = osm_bus_points.osm_id
;
