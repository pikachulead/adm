# ADM Local Development Guide

## Prerequisites

- **Node.js 22** — [download](https://nodejs.org/)
- **Docker Engine** — [install guide](https://docs.docker.com/engine/install/)
- **Git** — [download](https://git-scm.com/)
- **LLM API key** — one of: Anthropic, Groq, OpenRouter, OpenAI, Together, or Ollama (local)

## 1. Clone and Install

```bash
git clone https://github.com/pikachulead/adm.git
cd adm
npm install
```

## 2. Configure Environment

```bash
cp .env.example .env.local
```

Edit `.env.local` with your values:

```properties
# Database connection (no changes needed for local Docker)
DATABASE_URL=postgresql://adm_user:adm_pass@localhost:5432/adm
DB_PROVIDER=postgresql

# LLM configuration — pick ONE provider and set its key
LLM_PROVIDER=groq
LLM_API_KEY=your-api-key-here
LLM_MODEL=llama-3.3-70b-versatile

# API authentication (leave empty to disable auth in dev)
ADM_API_USER=
ADM_API_PASSWORD=

# Server port
API_PORT=3001
```

### Supported LLM Providers

| Provider | LLM_PROVIDER | LLM_MODEL (example) | Get API Key |
|---|---|---|---|
| Anthropic | `anthropic` | `claude-sonnet-4-6` | https://console.anthropic.com/ |
| Groq | `groq` | `llama-3.3-70b-versatile` | https://console.groq.com/ |
| OpenRouter | `openrouter` | `anthropic/claude-sonnet-4` | https://openrouter.ai/keys |
| OpenAI | `openai` | `gpt-4o` | https://platform.openai.com/ |
| Together | `together` | `meta-llama/Llama-3-70b` | https://api.together.xyz/ |
| Ollama | `ollama` | `llama3` | No key needed (runs locally) |
| Custom | any name | your model | Set `LLM_BASE_URL` to your endpoint |

For a custom provider, also set:

```properties
LLM_BASE_URL=https://your-llm-endpoint.example.com/v1
```

## 3. Start PostgreSQL

```bash
docker compose up -d
```

This pulls `postgres:16-alpine`, creates the `adm` database, and runs the SQL init scripts (`db/init/01_adm.sql` and `db/init/02_adm_metadata.sql`) automatically on first start.

Verify it's running:

```bash
docker compose ps
```

### Resetting the Database

To wipe and recreate the database from scratch:

```bash
docker compose down -v
docker compose up -d
```

The `-v` flag removes the data volume, so init scripts run again on next start.

## 4. Start the API Server

```bash
cd api
npm run dev
```

The API starts on `http://localhost:3001`. Verify:

```bash
curl http://localhost:3001/api/health
# {"status":"ok","database":"connected"}
```

## 5. Start the Frontend

In a separate terminal:

```bash
cd frontend
npm run dev
```

The frontend starts on `http://localhost:5173` with a proxy to the API.

## 6. Open the Application

Open `http://localhost:5173` in your browser.

### Things to Try

- Click **Navigate Org** in the header to see the full organization graph
- Use the **graph search box** to find and focus on specific nodes
- Click any **node card** to see its details in the right panel
- Click any **relationship edge** to see its attributes
- Type a question in the chat panel:
  - "Where does FNOL exist in the organization?"
  - "What systems are impacted by Java?"
  - "Show me all capabilities in the Claims domain"
  - "What technologies does the Billing Platform use?"

## Running Tests

```bash
# API tests (87 integration + unit tests)
npm test --workspace=@adm/api

# Frontend tests (7 unit tests)
npm test --workspace=@adm/frontend

# Both
npm test --workspace=@adm/api && npm test --workspace=@adm/frontend
```

## TypeScript Type Checking

```bash
cd api && npx tsc --noEmit
cd frontend && npx tsc --noEmit
```

## Project Structure

```
adm/
├── api/                        # Backend (Node.js + TypeScript)
│   ├── src/
│   │   ├── handlers/           # Lambda handlers (search, expand, update, health, org)
│   │   ├── lambda/             # AWS Lambda entry point adapters
│   │   ├── repositories/       # IArchitectureRepository + PostgreSQL implementation
│   │   ├── llm/                # ILlmProvider + Anthropic/OpenAI-compatible providers
│   │   ├── agent/              # Agent service, tools, system prompt
│   │   ├── services/           # Graph transformer
│   │   ├── middleware/         # Auth, validation, timeout
│   │   ├── types/              # TypeScript types
│   │   └── server.ts           # Hono local dev server
│   └── vitest.config.ts
├── frontend/                   # React SPA (Vite + Tailwind + React Flow)
│   ├── src/
│   │   ├── components/         # graph/, chat/, detail/, ErrorToast
│   │   ├── hooks/              # useArchitectureSearch
│   │   ├── api/                # API client
│   │   ├── constants/          # Node colors, edge colors
│   │   ├── i18n/               # UI strings
│   │   └── types/              # Frontend types
│   └── vite.config.ts
├── infra/                      # AWS CDK infrastructure
├── db/init/                    # SQL init scripts
├── docker-compose.yml          # PostgreSQL container
├── .env.example                # Environment variable template
└── .env.local                  # Your local config (gitignored)
```

## Troubleshooting

### "DATABASE_URL environment variable is required"

Make sure `.env.local` exists in the project root (not in `api/`) with the `DATABASE_URL` set.

### "Connection refused" on PostgreSQL

```bash
docker compose ps    # Check if container is running
docker compose logs  # Check for init script errors
```

### Port 3001 already in use

```bash
lsof -ti:3001 | xargs kill -9
```

### Port 5432 already in use

Another PostgreSQL instance may be running. Stop it or change the port in `docker-compose.yml` and `.env.local`.

### LLM API errors (413, 429, etc.)

- **413 Request too large** — your model's context window is too small for the system prompt. Switch to a model with larger context (e.g., `llama-3.3-70b-versatile` on Groq).
- **429 Rate limited** — you've hit the provider's rate limit. Wait or upgrade your plan.
- **401 Unauthorized** — check your `LLM_API_KEY` in `.env.local`.
