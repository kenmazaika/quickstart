#!/bin/bash

DB_HOSTNAME="`cat /kubernetes-secrets/metropolis-quickstart-database-credentials/host`"
DB_USERNAME="`cat /kubernetes-secrets/metropolis-quickstart-database-credentials/username`"
DB_PASSWORD="`cat /kubernetes-secrets/metropolis-quickstart-database-credentials/password`"    
DIR="`pwd`/config"

echo "production:
  adapter: postgresql
  encoding: unicode
  database: metro-backend-database
  pool: 5
  port: 5432
  host: ${DB_HOSTNAME}
  username: ${DB_USERNAME}
  password: ${DB_PASSWORD}" > "$DIR/database.yml"

echo "`cat /kubernetes-secrets/metropolis-quickstart-rails-master-key/value`" > "$DIR/master.key"

echo "> Production mounted"