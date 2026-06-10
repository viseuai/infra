#!/bin/bash
# Runs once on first postgres start (empty volume): keycloak database + role.
set -e

psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" <<-EOSQL
  CREATE USER keycloak WITH PASSWORD '$KEYCLOAK_DB_PASSWORD';
  CREATE DATABASE keycloak OWNER keycloak;
EOSQL
