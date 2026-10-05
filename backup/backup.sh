#!/bin/bash
set -euo pipefail

TS=$(date +%Y%m%d%H%M%S)
FILE="/tmp/backup-${TS}"
BUCKET="bucket-codigo-backup-425124975738-us-east-2-an"
PREFIX="${S3_PREFIX:-diaz-carlo/database}"

case "$MY_DATABASE_DRIVER" in
  mysql)
    FILE="${FILE}.sql"
    mysqldump -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER_NAME" -p"$DB_PASSWORD" "$DB_NAME" > "$FILE"
    ;;
  postgres)
    FILE="${FILE}.sql"
    PGPASSWORD="$DB_PASSWORD" pg_dump -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER_NAME" "$DB_NAME" > "$FILE"
    ;;
  mongo)
    FILE="${FILE}.archive"
    mongodump --host "$DB_HOST" --port "$DB_PORT" -u "$DB_USER_NAME" -p "$DB_PASSWORD" \
      --authenticationDatabase admin --db "$DB_NAME" --archive="$FILE"
    ;;
  *) echo "Driver no soportado"; exit 1 ;;
esac

aws s3 cp "$FILE" "s3://${BUCKET}/${PREFIX}/${TS}/$(basename "$FILE")"
echo "Backup subido a s3://${BUCKET}/${PREFIX}/${TS}/"