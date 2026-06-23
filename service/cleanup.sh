#!/bin/sh
while true; do
    echo "[$(date -Iseconds)] Running cleanup..."

    psql -c "
        DELETE FROM photos WHERE created_at < NOW() - INTERVAL '11 minutes';
        DELETE FROM users WHERE created_at < NOW() - INTERVAL '11 minutes';
        DELETE FROM tags WHERE tag NOT IN (SELECT tag FROM photos_tags);
    "

    echo "[$(date -Iseconds)] Cleanup done. Sleeping for 120 seconds."
    sleep 120
done
