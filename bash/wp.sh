#!/bin/bash

export $(grep -v '^#' .env | xargs)

case $1 in
  "init")
    mysql --user=$DB_USER --password=$DB_PASS --host=$DB_HOST --port=$DB_PORT --execute="CREATE DATABASE $DB_NAME;"

    wp core download
    wp config create --dbname=$DB_NAME --dbuser=$DB_USER --dbpass=$DB_PASS --dbhost=$DB_HOST --dbcharset=utf8mb4 --dbcollate=utf8mb4_general_ci
    wp core install --url=https://$DOMAIN_LOCAL --title=$TITLE --admin_user=$ADMIN_LOGIN --admin_password=$ADMIN_PASS --admin_email="$ADMIN_EMAIL" --skip-email
    wp plugin delete hello akismet
    wp theme delete twentytwentyone twentytwentytwo
    wp plugin install wordpress-seo
    wp comment delete 1 --force
    wp option update default_comment_status closed
    wp option update default_ping_status closed
    wp rewrite structure '/%postname%/'
    wp config set WP_DEBUG true --raw
    wp config set WP_DEBUG_DISPLAY true --raw
    wp config set WP_DEBUG_LOG true --raw
    wp config set WP_ENVIRONMENT_TYPE development
    wp config set DISALLOW_FILE_EDIT true --raw
    wp config set WP_AUTO_UPDATE_CORE true --raw

    curl https://raw.githubusercontent.com/przemekhernik/templates/main/gitignore/.gitignore.wp -o .gitignore
    curl https://raw.githubusercontent.com/przemekhernik/templates/main/htaccess/.htaccess.wp -o .htaccess
    curl https://raw.githubusercontent.com/przemekhernik/templates/main/htaccess/.htpasswd.wpt -o .htpasswd

    open "https://$DOMAIN_LOCAL"
    ;;

  "db:export")
    mysqldump --user=$DB_USER --password=$DB_PASS --host=$DB_HOST $DB_NAME --port=$DB_PORT | gzip > db.sql.gz
    ;;

  "db:export:staging")
    wp search-replace $DOMAIN_LOCAL $DOMAIN_STAGING --all-tables
    mysqldump --user=$DB_USER --password=$DB_PASS --host=$DB_HOST $DB_NAME --port=$DB_PORT | gzip > db.sql.gz
    wp search-replace $DOMAIN_STAGING $DOMAIN_LOCAL --all-tables
    ;;

  "db:export:prod")
    wp search-replace $DOMAIN_LOCAL $DOMAIN_PROD --all-tables
    mysqldump --user=$DB_USER --password=$DB_PASS --host=$DB_HOST $DB_NAME --port=$DB_PORT | gzip > db.sql.gz
    wp search-replace $DOMAIN_PROD $DOMAIN_LOCAL --all-tables
    ;;

  "db:import")
    gzip -d db.sql.gz
    mysql --user=$DB_USER --password=$DB_PASS --host=$DB_HOST $DB_NAME --port=$DB_PORT < db.sql
    rm db.sql
    ;;

  "db:import:staging")
    gzip -d db.sql.gz
    mysql --user=$DB_USER --password=$DB_PASS --host=$DB_HOST $DB_NAME --port=$DB_PORT < db.sql
    rm db.sql
    wp search-replace $DOMAIN_STAGING $DOMAIN_LOCAL --all-tables
    ;;

  "db:import:prod")
    gzip -d db.sql.gz
    mysql --user=$DB_USER --password=$DB_PASS --host=$DB_HOST $DB_NAME --port=$DB_PORT < db.sql
    rm db.sql
    wp search-replace $DOMAIN_PROD $DOMAIN_LOCAL --all-tables
    ;;

  *)
    echo "ERR: No task found."
    ;;
esac