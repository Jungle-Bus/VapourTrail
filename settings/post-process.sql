-- requête pour construire la liste des parcours de chaque arrêt :
drop table if exists osm_stops;

select json_agg(routes_at_stop), osm_id into osm_stops from
	(select row_to_json(t) as routes_at_stop, osm_id from
		(select
			osm_bus_points.osm_id,
			osm_bus_route_members.rel_osm_id,
			osm_bus_route_members.transport_mode,
			osm_bus_route_members.rel_network ,
			osm_bus_route_members.rel_ref,
			osm_bus_route_members.rel_destination,
			osm_bus_route_members.rel_colour
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
