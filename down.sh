#!/bin/bash

source .env

if docker compose version >/dev/null 2>&1; then
  COMPOSE_CMD=(docker compose)
elif command -v docker-compose >/dev/null 2>&1; then
  COMPOSE_CMD=(docker-compose)
else
  echo "Docker Compose not found. Install Docker Compose v2 ('docker compose') or v1 ('docker-compose')."
  exit 127
fi

if [ -n "$("${COMPOSE_CMD[@]}" --profile webtop ps -a -q webtop-browser)" ]; then
  "${COMPOSE_CMD[@]}" --profile webtop rm -fs webtop-browser || true
fi

"${COMPOSE_CMD[@]}" down --remove-orphans

# docker ps -aq | sudo xargs docker stop
# docker ps -aq | sudo xargs docker rm

# docker-compose stop
# docker-compose rm
