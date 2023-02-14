# pull stable postgres 15 alpine image from docker hub 
FROM postgres:15-alpine
# login to the database as postgres user
USER postgres
# create a database named "bddominion" and a user named "dominion" with password "dominion"
# grant all privileges to the user "dominion" on the database "bddominion"
# using the command "psql" (postgres interactive terminal)
RUN /usr/local/bin/docker-entrypoint.sh postgres --username=postgres --dbname=bddominion --create \
    && psql -c "CREATE USER dominion WITH PASSWORD 'dominion';" \
    && psql -c "GRANT ALL PRIVILEGES ON DATABASE bddominion TO dominion;"

# Execute all the queries inside 'database/schema' folder using psql
# with the user "dominion" and the database "bddominion"
# queries are executed in alphabetical order
COPY database/schema /docker-entrypoint-initdb.d/











