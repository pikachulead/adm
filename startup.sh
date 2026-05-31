#!/bin/bash

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
LOG_DIR="$PROJECT_DIR/.logs"
mkdir -p "$LOG_DIR"

echo "=== ADM Local Development Startup ==="
echo ""

# 1. Start PostgreSQL
echo "[1/3] Starting PostgreSQL..."
cd "$PROJECT_DIR"
docker compose up -d 2>&1

echo "       Waiting for PostgreSQL to be ready..."
for i in $(seq 1 30); do
  if docker compose exec -T postgres pg_isready -U adm_user -d adm > /dev/null 2>&1; then
    echo "       PostgreSQL is ready."
    break
  fi
  if [ "$i" -eq 30 ]; then
    echo "       ERROR: PostgreSQL did not start in time."
    exit 1
  fi
  sleep 1
done

# 2. Start API server
echo "[2/3] Starting API server on :3001..."
cd "$PROJECT_DIR/api"
npx tsx src/server.ts > "$LOG_DIR/api.log" 2>&1 &
echo $! > "$LOG_DIR/api.pid"

sleep 2
if curl -s http://localhost:3001/api/health > /dev/null 2>&1; then
  echo "       API server is ready."
else
  echo "       WARNING: API health check failed. Check $LOG_DIR/api.log"
fi

# 3. Start frontend
echo "[3/3] Starting frontend on :5173..."
cd "$PROJECT_DIR/frontend"
npx vite > "$LOG_DIR/frontend.log" 2>&1 &
echo $! > "$LOG_DIR/frontend.pid"

sleep 2
if curl -s -o /dev/null -w "%{http_code}" http://localhost:5173 | grep -q "200"; then
  echo "       Frontend is ready."
else
  echo "       WARNING: Frontend not responding yet. Check $LOG_DIR/frontend.log"
fi

echo ""
echo "=== All services started ==="
echo ""
echo "  Frontend:  http://localhost:5173"
echo "  API:       http://localhost:3001"
echo "  API logs:  $LOG_DIR/api.log"
echo "  FE logs:   $LOG_DIR/frontend.log"
echo ""
echo "  Run ./shutdown.sh to stop all services."
