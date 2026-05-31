#!/bin/bash

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
LOG_DIR="$PROJECT_DIR/.logs"

echo "=== ADM Local Development Shutdown ==="
echo ""

# 1. Stop frontend
if [ -f "$LOG_DIR/frontend.pid" ]; then
  PID=$(cat "$LOG_DIR/frontend.pid")
  if kill -0 "$PID" 2>/dev/null; then
    echo "[1/3] Stopping frontend (PID $PID)..."
    kill "$PID" 2>/dev/null
    wait "$PID" 2>/dev/null
  else
    echo "[1/3] Frontend already stopped."
  fi
  rm -f "$LOG_DIR/frontend.pid"
else
  echo "[1/3] No frontend PID file found. Killing port 5173..."
  lsof -ti:5173 | xargs kill -9 2>/dev/null || true
fi

# 2. Stop API server
if [ -f "$LOG_DIR/api.pid" ]; then
  PID=$(cat "$LOG_DIR/api.pid")
  if kill -0 "$PID" 2>/dev/null; then
    echo "[2/3] Stopping API server (PID $PID)..."
    kill "$PID" 2>/dev/null
    wait "$PID" 2>/dev/null
  else
    echo "[2/3] API server already stopped."
  fi
  rm -f "$LOG_DIR/api.pid"
else
  echo "[2/3] No API PID file found. Killing port 3001..."
  lsof -ti:3001 | xargs kill -9 2>/dev/null || true
fi

# 3. Stop PostgreSQL
echo "[3/3] Stopping PostgreSQL..."
cd "$PROJECT_DIR"
docker compose stop 2>&1

echo ""
echo "=== All services stopped ==="
