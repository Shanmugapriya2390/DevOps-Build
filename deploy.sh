#!/usr/bin/env bash
set -euo pipefail

APP_DIR="${APP_DIR:-/opt/devops-build}"

cd "${APP_DIR}"
docker compose pull
docker compose up -d --remove-orphans
