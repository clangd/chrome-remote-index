#!/bin/bash

# Abort script on failure.
set -e
# Print commands as we execute them.
set -x

touch crontab_schedule.txt

for ASSET_PORT_PAIR in $INDEX_ASSET_PORT_PAIRS
do
  INDEX_ASSET_PREFIX=${ASSET_PORT_PAIR%:*}
  PORT=${ASSET_PORT_PAIR#*:}
  INDEX_FILE="/${INDEX_ASSET_PREFIX}.idx"
  INDEX_FETCHER_CMD="/index_fetcher.sh $REPOSITORY $INDEX_ASSET_PREFIX $INDEX_FILE"

  # Run index fetcher once every 6 hours.
  echo "0 */6 * * * $INDEX_FETCHER_CMD" >> crontab_schedule.txt
  # Fetch index once.
  $INDEX_FETCHER_CMD
  # Start the server.
  /clangd-index-server $INDEX_FILE $INDEXER_PROJECT_ROOT -log-public \
    -server-address="0.0.0.0:${PORT}" &
done

crontab crontab_schedule.txt
cron -f
