

Création de la base de données
```
sudo -u postgres bash -c "createdb -E UTF8 -T template0 -O ubuntu data;"
sudo -u postgres psql -c "CREATE extension hstore; CREATE extension postgis;" data
```
Import des données
`imposm3 import -mapping ./settings/imposm_import.yml -read ./data/data.osm.pbf -overwritecache -write -connection postgis://ubuntu@localhost/data -deployproduction `

Post-process 
`post-process.sql`

Lancement du serveur de tuiles
`t_rex serve -c ./settings/trex.toml --simplify true`

