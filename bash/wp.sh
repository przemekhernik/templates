#!/bin/bash

case $1 in
  "init")
    clear

    read -e -p "Project: Slug: " PROJECT_SLUG
    read -e -p "Project: Name: " PROJECT_TITLE
    read -e -p "Project: Domain: " PROJECT_DOMAIN

    PROJECT_SLUG=${PROJECT_SLUG:-"acme"}
    PROJECT_TITLE=${PROJECT_TITLE:-"ACME"}
    PROJECT_DOMAIN=${PROJECT_DOMAIN:-"acme.test"}

    echo

    read -e -p "DB: User: " DB_USER
    read -e -p "DB: Password: " DB_PASS
    read -e -p "DB: Host: " DB_HOST
    read -e -p "DB: Port: " DB_PORT
    read -e -p "DB: Name: " DB_NAME

    DB_USER=${DB_USER:-"root"}
    DB_PASS=${DB_PASS:-"root"}
    DB_HOST=${DB_HOST:-"127.0.0.1"}
    DB_PORT=${DB_PORT:-"3306"}
    DB_NAME=${DB_NAME:-$PROJECT_SLUG}

    echo
    
    read -e -p "Admin: Login: " ADMIN_LOGIN
    read -e -p "Admin: Password: " ADMIN_PASS
    read -e -p "Admin: Email: " ADMIN_EMAIL

    ADMIN_LOGIN=${ADMIN_LOGIN:-"webmaster"}
    ADMIN_PASS=${ADMIN_PASS:-"test1234"}
    ADMIN_EMAIL=${ADMIN_EMAIL:-"admin@acme.test"}

    echo

    mysql --user=$DB_USER --password=$DB_PASS --host=$DB_HOST --port=$DB_PORT --execute="CREATE DATABASE $DB_NAME;"

    wp core download
    wp config create --dbname=$DB_NAME --dbuser=$DB_USER --dbpass=$DB_PASS --dbhost=$DB_HOST --dbcharset=utf8mb4 --dbcollate=utf8mb4_general_ci
    wp core install --url=https://$PROJECT_DOMAIN --title=$PROJECT_TITLE --admin_user=$ADMIN_LOGIN --admin_password=$ADMIN_PASS --admin_email="$ADMIN_EMAIL" --skip-email
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

    open "https://$PROJECT_DOMAIN"
    ;;

  "db:export")
    mysqldump --user=root --password=root --host=127.0.0.1 acme | gzip > db.sql.gz
    ;;

  "db:export:staging")
    wp search-replace acme.test acme.staging --all-tables
    mysqldump --user=root --password=root --host=127.0.0.1 acme | gzip > db.sql.gz
    wp search-replace acme.staging acme.test --all-tables
    ;;

  "db:export:prod")
    wp search-replace acme.test acme.prod --all-tables
    mysqldump --user=root --password=root --host=127.0.0.1 acme | gzip > db.sql.gz
    wp search-replace acme.prod acme.test --all-tables
    ;;

  "db:import")
    gzip -d db.sql.gz
    mysql --user=root --password=root --host=127.0.0.1 acme < db.sql
    rm db.sql
    ;;

  "db:import:staging")
    gzip -d db.sql.gz
    mysql --user=root --password=root --host=127.0.0.1 acme < db.sql
    rm db.sql
    wp search-replace acme.staging acme.test --all-tables
    ;;

  "db:import:prod")
    gzip -d db.sql.gz
    mysql --user=root --password=root --host=127.0.0.1 acme < db.sql
    rm db.sql
    wp search-replace acme.prod acme.test --all-tables
    ;;

  *)
    echo "ERR: No task found."
    ;;
esac



      