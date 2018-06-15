from flask_restful import Resource, Api
from flask import send_from_directory
from vapour_api import app
from geojson import Feature, Point
from flask_sqlalchemy import SQLAlchemy
from flask_cors import CORS, cross_origin
from collections import OrderedDict
import psycopg2
import ast
import os

db = SQLAlchemy(app)
CORS(app)
app.config['CORS_HEADERS'] = 'Content-Type'

ATTRIBUTION = "Jungle Bus, <a href='https://www.openstreetmap.org/copyright/'>© OpenStreetMap contributors</a>"

app.config['SQLALCHEMY_DATABASE_URI'] = 'postgresql://{}:{}@{}:{}/{}'.format(
    os.getenv('POSTGRES_USER', ''),
    os.getenv('POSTGRES_PASSWORD', ''),
    os.getenv('POSTGRES_HOST', ''),
    os.getenv('POSTGRES_PORT', ''),
    os.getenv('POSTGRES_DB', ''),
)

def get_route_properties(route_id):
    fields = ["osm_id", "name", "ref", "network", "origin", "destination", "colour", "operator"]
    result = db.engine.execute("SELECT {} FROM i_routes where osm_id = {}".format(
        ", ".join(fields),
        route_id)
    )
    row = result.next()
    route = {}
    for i, f in enumerate(fields):
        route[f] = row[i]
    return route

def get_route_geojson(route_id):
    sql = """
        SELECT ST_asgeojson(ST_MakeLine((ST_Transform(geom, 4326))))
        FROM i_ways
        WHERE rel_osm_id = {}
    """
    result = db.engine.execute(sql.format(route_id))
    row = result.next()
    return row[0]

def get_route_stop_positions(route_id):
    result = db.engine.execute(
        """
            SELECT 
                pos,
                st_asGeoJSON(ST_Transform(geom, 4326)) as geojson, 
                st_X(ST_Transform(geom, 4326)) as lon,
                st_Y(ST_Transform(geom, 4326)) as lat
            FROM (
                SELECT rel_osm_id, unnest(positions_ids) as pos
                FROM d_routes_position_ids
            ) t 
            INNER JOIN d_routes_position 
                on t.pos = d_routes_position.id
            WHERE rel_osm_id = {} 
            ORDER BY pos
        """.format(route_id)
    )
    route_stop_positions = []
    for row in result:
        s = {
            "route_position_id": row[0],
            "geojson": ast.literal_eval(row[1]),
            "lat": row[2],
            "lon": row[3],
        }
        route_stop_positions.append(s)
    return route_stop_positions

def get_route_stops_with_connections(route_id):
    result = db.engine.execute(
        """
            SELECT distinct i_positions.member_osm_id, i_positions.member_type, 
                i_positions.member_index, 
                i_stops.name,
                st_asGeoJSON(ST_Transform(i_positions.geom, 4326)), 
                st_X(ST_Transform(i_positions.geom, 4326)) as lon,
                st_Y(ST_Transform(i_positions.geom, 4326)) as lat,
                array_agg(distinct 
                    array_append(
	                    array_append(
	                    	array_append(Array[]::text[], other_routes.osm_id || ''),
		                    	other_routes.ref || ''
	                	),
                    	other_routes.colour || ''
                	)
                ) 
            FROM i_positions 
            	INNER JOIN i_stops on i_positions.member_osm_id = i_stops.osm_id
                LEFT JOIN i_positions AS other_positions ON
                    other_positions.member_type = i_positions.member_type AND
                    other_positions.member_osm_id = i_positions.member_osm_id AND
                    other_positions.rel_osm_id != {route_id}
                LEFT JOIN i_routes AS other_routes ON
                    other_routes.osm_id = other_positions.rel_osm_id
            WHERE i_positions.rel_osm_id = {route_id}
            GROUP BY i_positions.member_osm_id, i_positions.member_type, i_positions.member_index, 
            	i_stops.name, i_positions.geom
            ORDER BY member_index
        """.format(route_id=route_id)
    )
    route_stops = []
    for row in result:
        s = {
            "member_osm_id": row[0],
            "member_type": row[1],
            "name": row[3],
            "geojson": ast.literal_eval(row[4]),
            "lon": row[5],
            "lat": row[6],
            "shields": [{"ref": f[1], "colour": f[2]} for f in sorted(row[7], key=lambda x: x[1]) if f[1]],
        }
        route_stops.append(s)
    return route_stops

class Index(Resource):
    def get(self):
        return {
            "links": [
                {
                    "href": "api.py/route/<route_id>"
                }
            ]
        }
            
class Route(Resource):
    def get(self, route_id):
        if route_id:
            r = OrderedDict([])
            route_properties = get_route_properties(route_id)
            r["route_info"] = route_properties
            route_stop_positions = get_route_stop_positions(route_id)
            r["stop_positions"] = [{'lat': sp["lat"], 'lon': sp["lon"]} for sp in route_stop_positions]
            
            route_stops = get_route_stops_with_connections(route_id)
            for s in route_stops:
                if s["member_type"] == 0:
                    s["osm_id"] = "node/"
                elif s["member_type"] == 1:
                    s["osm_id"] = "way/"
                else : 
                    s["osm_id"] = "relation/"
                s["osm_id"] = s["osm_id"] + str(s["member_osm_id"])
                s.pop("member_type")
                s.pop("member_osm_id")
                s.pop("geojson")
            r["stop_list"] = route_stops
            r["geometry"] = ast.literal_eval(get_route_geojson(route_id))
            r["attribution"] = ATTRIBUTION
            return r
        else:
            return {}


api = Api(app)
api.add_resource(Index, '/')
api.add_resource(Route, '/route/', '/route/<string:route_id>')


if __name__ == '__main__':
    app.run(debug=True)