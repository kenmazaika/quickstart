#!/bin/bash
echo "Mounting via CloudProxy for CloudSQL"

echo "> Mounting secrets"

DIR="`pwd`/config"

DB_HOSTNAME="/tmp/csql/$PROXY_INSTANCE_NAME"
DB_USERNAME="metropolis"
DB_PASSWORD=`cat /workspace/.metropolis-secrets/metropolis-quickstart-database-credentials/password`
METROPOLIS_RAILS_MASTER_KEY=`cat /workspace/.metropolis-secrets/metropolis-quickstart-rails-master-key/value`

rm $DIR/database.yml

echo "> Generating database.yml for cloud_sql_proxy database connection"

echo "production:
  adapter: postgresql
  encoding: unicode
  database: metro-backend-database-$SANDBOX_ID
  pool: 5
  port: 5432
  host: ${DB_HOSTNAME}
  username: ${DB_USERNAME}
  password: ${DB_PASSWORD}" > "$DIR/database.yml"


echo "> Built configuration file"
cat $DIR/database.yml

echo $METROPOLIS_RAILS_MASTER_KEY > "$DIR/master.key"

echo "> Staging mounted"