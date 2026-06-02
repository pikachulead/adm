#!/bin/bash

set -e

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
ENV_FILE="$PROJECT_DIR/.env.local"

echo "=== ADM Metadata Embeddings Generator ==="
echo ""

# ── Load .env.local ───────────────────────────────────────────────────────────

if [ ! -f "$ENV_FILE" ]; then
  echo "ERROR: $ENV_FILE not found."
  echo "       Copy .env.example to .env.local and fill in the values."
  exit 1
fi

set -a
# shellcheck source=/dev/null
source "$ENV_FILE"
set +a

# ── Validate config ────────────────────────────────────────────────────────────

if [ -z "$DATABASE_URL" ]; then
  echo "ERROR: DATABASE_URL is not set in .env.local"
  exit 1
fi

if [ -z "$EMBEDDING_API_KEY" ]; then
  echo "ERROR: EMBEDDING_API_KEY is not set in .env.local"
  exit 1
fi

EMBEDDING_MODEL="${EMBEDDING_MODEL:-text-embedding-3-small}"
EMBEDDING_PROVIDER="${EMBEDDING_PROVIDER:-openai}"

echo "  Database:   $DATABASE_URL"
echo "  Provider:   $EMBEDDING_PROVIDER (via OpenRouter)"
echo "  Model:      $EMBEDDING_MODEL"
echo ""

# ── Check PostgreSQL is reachable ─────────────────────────────────────────────

echo "[1/4] Checking PostgreSQL connection..."
if ! docker compose -f "$PROJECT_DIR/docker-compose.yml" exec -T postgres \
    pg_isready -U adm_user -d adm > /dev/null 2>&1; then
  echo "       PostgreSQL not ready. Starting container..."
  docker compose -f "$PROJECT_DIR/docker-compose.yml" up -d
  sleep 4
fi
echo "       PostgreSQL is ready."
echo ""

# ── Truncate and reload adm_metadata ─────────────────────────────────────────

echo "[2/4] Reloading adm_metadata from adm_metadata_v2.sql..."

docker compose -f "$PROJECT_DIR/docker-compose.yml" exec -T postgres \
  psql -U adm_user -d adm -c "
    TRUNCATE TABLE adm_metadata_embeddings;
    TRUNCATE TABLE adm_metadata CASCADE;
  " > /dev/null

docker compose -f "$PROJECT_DIR/docker-compose.yml" exec -T postgres \
  psql -U adm_user -d adm \
  -f /dev/stdin < "$PROJECT_DIR/adm_metadata_v2.sql" > /dev/null

ROW_COUNT=$(docker compose -f "$PROJECT_DIR/docker-compose.yml" exec -T postgres \
  psql -U adm_user -d adm -t -c "SELECT COUNT(*) FROM adm_metadata;" | tr -d ' ')

echo "       Loaded $ROW_COUNT records into adm_metadata."
echo ""

# ── Generate embeddings ───────────────────────────────────────────────────────

echo "[3/4] Generating embeddings via OpenRouter..."
cd "$PROJECT_DIR"
npx tsx scripts/generate-embeddings.ts
echo ""

# ── Import CSV into PostgreSQL ────────────────────────────────────────────────

CSV_FILE="$PROJECT_DIR/adm_metadata_embeddings.csv"

if [ ! -f "$CSV_FILE" ]; then
  echo "ERROR: CSV file not found at $CSV_FILE"
  exit 1
fi

echo "[4/4] Importing embeddings CSV into adm_metadata_embeddings..."

# Copy CSV into container and import
docker cp "$CSV_FILE" adm-postgres-1:/tmp/adm_metadata_embeddings.csv

docker compose -f "$PROJECT_DIR/docker-compose.yml" exec -T postgres \
  psql -U adm_user -d adm -c "
    COPY adm_metadata_embeddings (
      metadata_id,
      metadata_code,
      metadata_object_type,
      metadata_name,
      metadata_source_table_name,
      metadata_source_column_name,
      content,
      embedding_model,
      embedding_dimensions,
      embedding
    )
    FROM '/tmp/adm_metadata_embeddings.csv'
    WITH (FORMAT CSV, HEADER true, NULL '');
  "

EMBED_COUNT=$(docker compose -f "$PROJECT_DIR/docker-compose.yml" exec -T postgres \
  psql -U adm_user -d adm -t -c "SELECT COUNT(*) FROM adm_metadata_embeddings;" | tr -d ' ')

echo ""
echo "=== Done ==="
echo ""
echo "  adm_metadata rows:            $ROW_COUNT"
echo "  adm_metadata_embeddings rows: $EMBED_COUNT"
echo "  CSV file:                     $CSV_FILE"
