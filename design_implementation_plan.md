# ADM Web Application — Implementation Plan

## Context

The ADM (Architecture Domain Model) repository at `github.com/pikachulead/adm` contains a PostgreSQL schema modeling enterprise architecture: 6 entity tables (domains, capabilities, processes, systems, technologies, data entities) and 7 bridge/relationship tables, seeded with 4 insurance domains. The goal is to build an AI agent-powered web application that lets users explore and manage this architecture through natural language search and graph visualization.

**Repo**: `github.com/pikachulead/adm`
**Existing files**: `adm.sql` (DDL + DML), `adm_metadata.sql` (model dictionary), `adm_analysis.md`

---

## Phase 0: Project Scaffolding and Database

**Goal**: Monorepo structure, Docker PostgreSQL running, database connectivity verified.

### Steps
1. Initialize npm workspace monorepo (`package.json` with workspaces: `frontend`, `api`, `infra`)
2. Move SQL files to `db/init/01_adm.sql` and `db/init/02_adm_metadata.sql` (numeric prefixes for Docker init ordering)
3. Create `docker-compose.yml` — single `postgres:16-alpine` service, mount `./db/init` to `/docker-entrypoint-initdb.d`
4. Create `api/` package with dependencies: `pg`, `@anthropic-ai/sdk`, `hono`, `@hono/node-server`; dev deps: `vitest`, `tsx`, `typescript`
5. Create `api/src/db/pool.ts` — pg Pool singleton reading `DATABASE_URL` from env
6. Create `.env.example` — **template only** with placeholder values, committed to git (documents required vars without exposing secrets)
7. Create `.env.local` — **actual secrets**, listed in `.gitignore`, never committed
8. Create `.gitignore` — must include: `.env.local`, `.env`, `.env.production`, `node_modules/`, `dist/`
9. Add `pg_trgm` extension to init SQL for fuzzy matching

### Secrets Management
- **No API keys or credentials ever committed to GitHub**
- `.env.example` committed as a template:
  ```
  DATABASE_URL=postgresql://user:password@localhost:5432/adm
  ANTHROPIC_API_KEY=sk-ant-your-key-here
  LLM_PROVIDER=anthropic
  LLM_MODEL=claude-sonnet-4-6
  ```
- `.env.local` is gitignored and holds actual values
- In production, secrets come from AWS Secrets Manager (Phase 7)
- CI/CD uses GitHub Actions secrets or equivalent

### Verification
- `docker compose up -d` starts PostgreSQL and runs init scripts
- **Test**: `api/src/db/__tests__/pool.test.ts` — connect, `SELECT COUNT(*) FROM business_domains`, assert 4

### Key Files
`package.json`, `docker-compose.yml`, `api/package.json`, `api/tsconfig.json`, `api/src/db/pool.ts`, `.env.example`, `.env.local` (gitignored), `.gitignore`

---

## Phase 1: Types, Database Abstraction, and Query Layer

**Goal**: TypeScript types, a data-source-agnostic repository interface, and tested query implementations.

### Database Abstraction Layer

The database is accessed exclusively through a **repository interface**. All handlers and services depend on the interface, never on `pg` directly. If Aurora PostgreSQL is replaced with another data source (DynamoDB, API, etc.), only the implementation changes — the contract stays intact.

```
api/src/
├── repositories/
│   ├── interfaces.ts              ← IArchitectureRepository interface (the contract)
│   ├── postgresql/
│   │   ├── pg-repository.ts       ← PostgreSQL implementation of IArchitectureRepository
│   │   └── pg-pool.ts             ← pg Pool singleton
│   └── index.ts                   ← factory: createRepository() returns the active implementation
```

**`IArchitectureRepository` interface** defines all data operations:
```typescript
interface IArchitectureRepository {
  searchByKeyword(keyword: string): Promise<SearchResult[]>;
  getFullPath(filters?: PathFilters): Promise<ArchitecturePath[]>;
  getReversePath(technologyName: string): Promise<ImpactPath[]>;
  expandNode(nodeType: EntityType, nodeId: string): Promise<ExpandResult>;
  findSimilar(entityType: EntityType, name: string): Promise<SimilarityMatch[]>;
  listEntities(entityType: EntityType): Promise<BaseEntity[]>;
  createEntity(entityType: EntityType, data: CreateEntityInput): Promise<BaseEntity>;
  getMetadata(types?: MetadataType[]): Promise<AdmMetadata[]>;
  healthCheck(): Promise<boolean>;
}
```

**`createRepository()` factory** reads config to decide which implementation:
```typescript
function createRepository(): IArchitectureRepository {
  const provider = process.env.DB_PROVIDER ?? 'postgresql';
  switch (provider) {
    case 'postgresql': return new PgArchitectureRepository(createPool());
    default: throw new Error(`Unknown DB provider: ${provider}`);
  }
}
```

### Steps
1. **`api/src/types/entities.ts`** — interfaces for all 6 entity tables + graph response types (`GraphNode`, `GraphEdge`, `SearchResponse`, `EntityType` union)
2. **`api/src/repositories/interfaces.ts`** — `IArchitectureRepository` interface defining all data operations
3. **`api/src/repositories/postgresql/pg-pool.ts`** — pg Pool singleton reading `DATABASE_URL` from env
4. **`api/src/repositories/postgresql/pg-repository.ts`** — PostgreSQL implementation with parameterized SQL:
   - `searchByKeyword(keyword)` — ILIKE search across all entity name columns via UNION
   - `getFullPath(filters?)` — Domain→Capability→Process→System→Technology join
   - `getReversePath(technologyName)` — reverse impact: Technology→System→Process→Capability→Domain
   - `expandNode(nodeType, nodeId)` — return direct children via appropriate bridge table
   - `findSimilar(entityType, name)` — trigram similarity for duplicate detection
   - `listEntities(entityType)` — list all of a given entity type
   - `createEntity(entityType, data)` — INSERT with conflict handling
   - `getMetadata(types?)` — query adm_metadata for system prompt building
5. **`api/src/repositories/index.ts`** — factory function
6. **`api/src/services/graph-transformer.ts`** — converts query results to `{ nodes: GraphNode[], edges: GraphEdge[] }`, deduplicates by ID

### Tests (integration, against Docker PostgreSQL)
- `searchByKeyword("FNOL")` returns results containing "First Notice of Loss"
- `getFullPath({ domain_name: 'Claims' })` returns rows with all 5 columns populated
- `getReversePath('Java')` returns rows spanning multiple domains
- `expandNode('domain', claimsDomainId)` returns 9 capabilities
- Graph transformer deduplicates nodes correctly
- All tests use the repository interface, not pg directly

---

## Phase 2: LLM Abstraction and Agent with Tool Use

**Goal**: A model-agnostic agent that receives natural language, calls an LLM with tools, executes queries via repository, returns structured response.

### LLM Abstraction Layer

The LLM is accessed through a **provider interface**. All agent logic depends on the interface, never on `@anthropic-ai/sdk` directly. If the team needs to switch from Claude to OpenAI, Bedrock, or another model, only the provider implementation changes.

```
api/src/
├── llm/
│   ├── interfaces.ts              ← ILlmProvider interface (the contract)
│   ├── types.ts                   ← LlmMessage, LlmToolCall, LlmResponse, ToolDefinition
│   ├── anthropic/
│   │   └── anthropic-provider.ts  ← Claude implementation of ILlmProvider
│   └── index.ts                   ← factory: createLlmProvider() returns the active implementation
```

**`ILlmProvider` interface** defines all LLM interactions:
```typescript
interface ILlmProvider {
  chat(params: {
    systemPrompt: string;
    messages: LlmMessage[];
    tools?: ToolDefinition[];
    maxTokens?: number;
  }): Promise<LlmResponse>;
}

interface LlmResponse {
  content: string | null;
  toolCalls: LlmToolCall[];
  stopReason: 'end_turn' | 'tool_use';
}
```

**`createLlmProvider()` factory** reads config:
```typescript
function createLlmProvider(): ILlmProvider {
  const provider = process.env.LLM_PROVIDER ?? 'anthropic';
  const model = process.env.LLM_MODEL ?? 'claude-sonnet-4-6';
  switch (provider) {
    case 'anthropic': return new AnthropicProvider(model);
    default: throw new Error(`Unknown LLM provider: ${provider}`);
  }
}
```

### Steps
1. **`api/src/llm/interfaces.ts`** — `ILlmProvider` interface and `LlmMessage`, `LlmToolCall`, `LlmResponse`, `ToolDefinition` types
2. **`api/src/llm/anthropic/anthropic-provider.ts`** — Claude implementation translating `ILlmProvider` calls to `@anthropic-ai/sdk` calls
3. **`api/src/llm/index.ts`** — factory function
4. **`api/src/agent/tools.ts`** — tool definitions using `ToolDefinition` type (provider-agnostic): `search_architecture`, `get_full_path`, `get_reverse_impact`, `expand_node`, `list_entities`, `suggest_similar`, `create_entity`
5. **`api/src/agent/tool-executor.ts`** — dispatches tool name + args to the correct repository method from Phase 1
6. **`api/src/agent/system-prompt.ts`** — builds system prompt from `adm_metadata` via repository (entity definitions, relationship semantics, value sets, query patterns). This is the key quality lever — ~50 metadata rows teaching the LLM the ADM model
7. **`api/src/agent/agent-service.ts`** — the core loop using `ILlmProvider` and `IArchitectureRepository`:
   - User message → LLM decides tool(s) → executor runs repository queries → results back to LLM → LLM formats answer
   - Accumulates graph nodes/edges from each tool call
   - Circuit breaker: max 10 tool calls per request
   - Returns `{ answer: string, graph: { nodes, edges } }`

### Dependency Injection
The agent service receives both abstractions via constructor/factory:
```typescript
function createAgentService(): AgentService {
  const llm = createLlmProvider();
  const repository = createRepository();
  return new AgentService(llm, repository);
}
```

### Tests
- Tool executor integration test with known inputs (via repository)
- Agent E2E test: "Where does FNOL exist?" → response contains "Claims" + graph nodes
- Agent E2E test: "What is impacted if Java is deprecated?" → response covers multiple domains
- System prompt builder produces string containing all entity names
- LLM provider unit test: mock ILlmProvider to verify agent loop logic independent of Claude

---

## Phase 3: API Handlers and Local Dev Server

**Goal**: Three HTTP endpoints, tested end-to-end.

### Endpoints
1. **`POST /api/search`** — `{ query }` → agent → `{ answer, graph }` (timeout: 60s)
2. **`POST /api/expand`** — `{ nodeType, nodeId }` → direct SQL, no agent → `{ nodes, edges }` (timeout: 5s)
3. **`POST /api/update`** — `{ request }` → agent with update tools → `{ answer, created? }`
4. **`GET /api/health`** — health check

### Steps
1. Create handler files in `api/src/handlers/` — each handler receives `AgentService` and `IArchitectureRepository` via dependency injection, never imports concrete implementations
2. Create `api/src/middleware/validation.ts` — lightweight input validation
3. Create `api/src/middleware/error-handler.ts` — Hono error handler (400/500/502)
4. Create `api/src/server.ts` — Hono app that creates dependencies via factories (`createRepository()`, `createLlmProvider()`, `createAgentService()`) and wires them into handlers + CORS for localhost:5173

### Tests
- POST /api/search with "FNOL" → 200 with answer and graph
- POST /api/expand with Claims domain UUID → capabilities returned
- POST /api/update with duplicate entity → agent detects existing match

---

## Phase 4: Frontend — React SPA with Graph Visualization

**Goal**: Working UI with search input, agent response panel, and interactive graph.

### Steps
1. **Vite + React + Tailwind setup** — `frontend/` package with proxy to `localhost:3001`
2. **i18n** — `frontend/src/i18n/en.ts` with all UI strings as key-value object, `t()` function
3. **API client** — `frontend/src/api/client.ts` — `searchArchitecture()`, `expandNode()`, `updatePortfolio()`
4. **Graph components**:
   - `AdmNode.tsx` — custom React Flow node card with colored header per entity type (Domain=blue, Capability=purple, Process=green, System=amber, Technology=red, DataEntity=cyan)
   - `GraphCanvas.tsx` — React Flow wrapper with Dagre layout, node click → expand
   - `layout.ts` — Dagre utility (`rankdir: 'TB'`, `nodesep: 80`, `ranksep: 100`)
5. **Chat components**:
   - `ChatPanel.tsx` — input area, message list, loading state
   - `MessageBubble.tsx` — user/agent message rendering
6. **Main layout** — `App.tsx` — two-panel: left=chat (~40%), right=graph (~60%)
7. **State hook** — `useArchitectureSearch.ts` — manages messages, graph nodes/edges, loading, `sendQuery()`, `expandNode()`

### Node Colors
| Type | Color |
|---|---|
| Domain | blue-600 |
| Capability | purple-600 |
| Process | green-600 |
| System | amber-600 |
| Technology | red-600 |
| Data Entity | cyan-600 |

### Tests
- Dagre layout unit test: 3 nodes + 2 edges → y positions increase downward
- AdmNode render test: domain node shows blue header
- useArchitectureSearch hook test with mocked fetch

---

## Phase 5: End-to-End Integration and Polish

**Goal**: Full flow working, edge cases handled.

### Steps
1. **E2E tests** (API-level via Vitest):
   - Search "FNOL" → answer mentions Claims + graph has domain/capability/process nodes
   - Expand Claims domain → 9 capability nodes
   - Impact analysis "Java" → multi-domain results
   - Duplicate detection on portfolio update
2. **Error states** — empty state, loading skeleton, error toast, "no results"
3. **Graph polish** — edge labels, fit-to-view button, minimap, node count indicator
4. **Guard rails** — 10-tool circuit breaker, 60s request timeout, 200-node graph cap
5. **CLAUDE.md** — project docs, startup commands, conventions

---

## Phase 6: DynamoDB for Chat History and Audit (deferred)

**Goal**: Persist conversations and portfolio change audit trail.

- **`adm-conversations`** table: PK=conversationId, SK=messageIndex
- **`adm-audit-log`** table: PK=changeId, SK=timestamp, attributes: entityType, action, requestText, agentResponse
- Add DynamoDB Local to docker-compose for dev
- Endpoints: `GET /api/conversations`, `GET /api/conversations/:id`

---

## Phase 7: AWS CDK Infrastructure (deferred)

**Goal**: Deployable to AWS.

- **DatabaseStack**: Aurora Serverless v2 PostgreSQL 16, VPC, security groups
- **ApiStack**: Lambda per handler, API Gateway HTTP API, Secrets Manager, RDS Proxy
- **FrontendStack**: S3 bucket + CloudFront distribution
- **StorageStack**: DynamoDB tables
- Lambda handler adapters converting API Gateway events → Hono-compatible requests

---

## Phase Sequencing

```
Phase 0 (Scaffolding + DB)
    │
Phase 1 (Types + Queries)
    │
Phase 2 (Agent)
    │
Phase 3 (API Handlers) ─────── Phase 4 (Frontend) ← can start in parallel with mocked API
    │                                │
    └────────────┬───────────────────┘
                 │
          Phase 5 (E2E + Polish)
                 │
          Phase 6 (DynamoDB) ← deferred
                 │
          Phase 7 (CDK) ← deferred
```

## Key Architectural Decisions

1. **LLM provider abstraction** — all agent logic depends on `ILlmProvider` interface, never on `@anthropic-ai/sdk` directly. Swap Claude for OpenAI/Bedrock/local model by implementing a new provider — no agent code changes. Provider selected via `LLM_PROVIDER` env var
2. **Database repository abstraction** — all data access goes through `IArchitectureRepository` interface, never through `pg` directly. Replace Aurora PostgreSQL with DynamoDB, an API, or another source by implementing the interface — contract stays intact. Provider selected via `DB_PROVIDER` env var
3. **No secrets on GitHub** — `.env.local` is gitignored; `.env.example` committed as a template documenting required variables. Production secrets via AWS Secrets Manager
4. **Agent gets raw query results, not pre-formatted answers** — lets the LLM reason about data and compose natural answers; graph JSON accumulated from tool results
5. **System prompt built from adm_metadata** — the 50+ metadata rows contain entity definitions, relationships, value sets, and query patterns; this is the single most important quality lever
6. **Expand is direct repository call, no agent** — latency matters on click; <100ms vs 2-5s through the LLM
7. **Graph state lives in frontend** — API returns subgraphs; frontend merges incrementally as user explores
8. **Same handler code for local dev and Lambda** — Hono locally, thin adapter for Lambda
9. **Dependency injection via factories** — `createRepository()`, `createLlmProvider()`, `createAgentService()` wire everything together. Tests can inject mocks for either abstraction independently
10. **pg_trgm for fuzzy matching** — trigram similarity for duplicate detection during portfolio updates
