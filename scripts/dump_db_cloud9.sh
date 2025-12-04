#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   ./dump_db_cloud9.sh <RDS_ENDPOINT> [db=ppa] [user=ppa] [port=5432]
# Env:
#   PGPASSWORD must be set to the DB user's password
#
# Example:
#   export PGPASSWORD='Automation'
#   ./dump_db_cloud9.sh mydb.abcdef.us-east-1.rds.amazonaws.com

RDS_ENDPOINT="${1:-}"
DB_NAME="${2:-ppa}"
DB_USER="${3:-ppa}"
DB_PORT="${4:-5432}"

if [[ -z "${RDS_ENDPOINT}" ]]; then
  echo "RDS endpoint is required. Usage: $0 <RDS_ENDPOINT> [db] [user] [port]" >&2
  exit 1
fi

if ! command -v pg_dump >/dev/null 2>&1; then
  echo "Installing PostgreSQL client..." >&2
  sudo dnf install -y postgresql15 >/dev/null
fi

STAMP="$(date +%Y%m%d_%H%M%S)"
OUT="ppa_${STAMP}.dump"
echo "Dumping ${DB_NAME} from ${RDS_ENDPOINT}:${DB_PORT} as ${DB_USER} -> ${OUT}"
pg_dump -h "${RDS_ENDPOINT}" -p "${DB_PORT}" -U "${DB_USER}" -d "${DB_NAME}" -Fc -f "${OUT}"
echo "Created ${OUT}"




