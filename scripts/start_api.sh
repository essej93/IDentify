#!/bin/bash

cd ../installed/identifyapi

echo "Starting IdentifyAPI's dependencies (docker containers)"


docker compose -f docker/docker-compose-local.yml up -d

export POSTGRES_PASS=Dev123! 
export POSTGRES_URL=jdbc:postgresql://localhost:5432/identify 
export POSTGRES_USER=identify 
export RABBIT_HOST=localhost 
export RABBIT_PORT=5671 

./mvnw spring-boot:run

docker compose -f docker/docker-compose-local.yml down
