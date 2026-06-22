#!/bin/bash
# Initialize the EQEmu database from the sanitized PEQ dump
set -e

DB_NAME="${MYSQL_DATABASE:-peq}"

# Find the most recent database dump
DUMP_DIR="/docker-entrypoint-initdb.d/database"

for tarball in "$DUMP_DIR"/*.tar.gz; do
    if [ -f "$tarball" ]; then
        echo "Extracting database dump: $tarball"
        tar -xzf "$tarball" -C /tmp/

        for sql_file in /tmp/*.sql; do
            if [ -f "$sql_file" ]; then
                echo "Importing $sql_file into $DB_NAME..."
                mysql -u root -p"$MYSQL_ROOT_PASSWORD" "$DB_NAME" < "$sql_file"
                echo "Database import complete."
                rm -f "$sql_file"
            fi
        done
    fi
done

echo "Database initialization finished."
