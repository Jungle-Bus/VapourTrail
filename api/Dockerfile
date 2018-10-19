FROM python:3.5.5-jessie

RUN apt update && \
    apt install python3-psycopg2 -y

RUN pip3 install flask flask-restful flask-cors geojson gunicorn SQLAlchemy flask_sqlalchemy psycopg2 


WORKDIR /
ENTRYPOINT gunicorn -w 4 -b 0.0.0.0:5000 --access-logfile - vapour_api:app

