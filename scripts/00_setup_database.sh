#!/bin/bash
# ============================================================
# OLIST E-COMMERCE ANALYTICS PROJECT
# Master Setup Script
#
# Reproduces the full database locally from scratch:
#   1. Creates the 'analyst' role and 'olist_ecommerce' database
#   2. Creates all 9 tables (schema/01_create_tables.sql)
#   3. Loads all 9 CSVs (schema/02_load_data.sql)
#   4. Runs validation checks (schema/03_validation_checks.sql)
#   5. Creates all indexes (schema/04_create_indexes.sql)
#
# Prerequisites:
#   - PostgreSQL installed and running locally
#   - All 9 Olist CSVs present in the /data folder (see data/README.md
#     for the exact filenames and download source)
#   - Run this script from the project root, e.g.:
#       bash scripts/00_setup_database.sh
#
# Edit DATA_DIR below if your CSVs live somewhere other than ./data
# ============================================================

set -e  # stop immediately on any error

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DATA_DIR="$PROJECT_ROOT/data"
SQL_DIR="$PROJECT_ROOT/sql/schema"
DB_NAME="olist_ecommerce"
DB_USER="analyst"
DB_PASSWORD="analyst_pw"

echo "=== Step 1: Creating role and database ==="
psql -U postgres -c "CREATE USER ${DB_USER} WITH PASSWORD '${DB_PASSWORD}' SUPERUSER;" || echo "  (role may already exist, continuing)"
psql -U postgres -c "CREATE DATABASE ${DB_NAME} OWNER ${DB_USER};" || echo "  (database may already exist, continuing)"

echo "=== Step 2: Creating tables ==="
psql -U postgres -d "${DB_NAME}" -f "${SQL_DIR}/01_create_tables.sql"

echo "=== Step 3: Loading CSV data ==="
# NOTE: 02_load_data.sql uses absolute paths by default.
# If your data lives elsewhere, either edit the \copy paths inside
# that file, or export DATA_DIR and adjust the script accordingly.
psql -U postgres -d "${DB_NAME}" -f "${SQL_DIR}/02_load_data.sql"

echo "=== Step 4: Running validation checks ==="
psql -U postgres -d "${DB_NAME}" -f "${SQL_DIR}/03_validation_checks.sql"

echo "=== Step 5: Creating indexes ==="
psql -U postgres -d "${DB_NAME}" -f "${SQL_DIR}/04_create_indexes.sql"

echo "=== Setup complete. Database '${DB_NAME}' is ready. ==="
echo "Connect with: psql -U ${DB_USER} -d ${DB_NAME}"
