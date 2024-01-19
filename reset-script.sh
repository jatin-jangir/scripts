#!/bin/bash
echo "testing connection"
PGPASSWORD=$PGPASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER_NAME -d $DB_NAME -t -c "\l"

echo "deleting and creating new DB"
PGPASSWORD=$PGPASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER_NAME -d $DB_NAME -t -c "DROP DATABASE $LENS_DB (FORCE);"
PGPASSWORD=$PGPASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER_NAME -d $DB_NAME -t -c "CREATE DATABASE $LENS_DB ;"

PGPASSWORD=$PGPASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER_NAME -d $DB_NAME -t -c "DROP DATABASE $GIT_SENSOR_DB (FORCE) ;"
PGPASSWORD=$PGPASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER_NAME -d $DB_NAME -t -c "CREATE DATABASE $GIT_SENSOR_DB ;"

PGPASSWORD=$PGPASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER_NAME -d $DB_NAME -t -c "DROP DATABASE $CASBIN_DB  (FORCE) ;"
PGPASSWORD=$PGPASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER_NAME -d $DB_NAME -t -c "CREATE DATABASE $CASBIN_DB ;"

PGPASSWORD=$PGPASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER_NAME -d $DB_NAME -t -c "DROP DATABASE $ORCHESTRATOR_DB (FORCE) ;"
PGPASSWORD=$PGPASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER_NAME -d $DB_NAME -t -c "CREATE DATABASE $ORCHESTRATOR_DB ;"

PGPASSWORD=$PGPASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER_NAME -d $DB_NAME -t -c "\l"

echo "git cloning and doing migration"
: "${DEVTRON_BRANCH:=main}"
: "${GIT_SENSOR_BRANCH:=main}"
: "${LENS_BRANCH:=main}"

DB_CRED="$DB_USER:$DB_PASSWORD@"

git clone https://github.com/devtron-labs/git-sensor -b $GIT_SENSOR_BRANCH
git clone https://github.com/devtron-labs/devtron -b $DEVTRON_BRANCH
git clone https://github.com/devtron-labs/lens -b $LENS_BRANCH


migrate -path ./devtron/scripts/sql -database postgres://$DB_CRED$DB_HOST:$DB_PORT/$ORCHESTRATOR_DB?sslmode=disable up;

migrate -path ./devtron/scripts/casbin  -database postgres://$DB_CRED$DB_HOST:$DB_PORT/$CASBIN_DB?sslmode=disable up;


migrate -path ./git-sensor/scripts/sql  -database postgres://$DB_CRED$DB_HOST:$DB_PORT/$GIT_SENSOR_DB?sslmode=disable up;


migrate -path ./lens/scripts/sql  -database postgres://$DB_CRED$DB_HOST:$DB_PORT/$LENS_DB?sslmode=disable up;

echo "done migration"

