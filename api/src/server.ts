import { Hono } from 'hono';
import { cors } from 'hono/cors';
import { serve } from '@hono/node-server';
import type { Context } from 'hono';
import type { LambdaEvent, LambdaResponse } from './handlers/lambda-utils.js';
import { handler as searchHandler } from './handlers/search.js';
import { handler as expandHandler } from './handlers/expand.js';
import { handler as updateHandler } from './handlers/update.js';
import { handler as healthHandler } from './handlers/health.js';
import { handler as orgHandler } from './handlers/org.js';
import { withTimeout } from './middleware/timeout.js';

const searchWithTimeout = withTimeout(searchHandler, 60_000);
const expandWithTimeout = withTimeout(expandHandler, 5_000);
const updateWithTimeout = withTimeout(updateHandler, 60_000);

const app = new Hono();

app.use('/*', cors({ origin: 'http://localhost:5173' }));

function lambdaAdapter(handler: (event: LambdaEvent) => Promise<LambdaResponse>) {
  return async (c: Context) => {
    const body = await c.req.text();
    const headers: Record<string, string> = {};
    c.req.raw.headers.forEach((value, key) => {
      headers[key] = value;
    });

    const event: LambdaEvent = {
      body: body || null,
      headers,
      requestContext: {
        http: {
          method: c.req.method,
          path: c.req.path,
        },
      },
      rawPath: c.req.path,
    };

    const result = await handler(event);
    return c.json(JSON.parse(result.body), result.statusCode as 200);
  };
}

app.post('/api/search', lambdaAdapter(searchWithTimeout));
app.post('/api/expand', lambdaAdapter(expandWithTimeout));
app.post('/api/update', lambdaAdapter(updateWithTimeout));
app.get('/api/org', lambdaAdapter(orgHandler));
app.get('/api/health', lambdaAdapter(healthHandler));

const port = parseInt(process.env.API_PORT ?? '3001', 10);

serve({ fetch: app.fetch, port }, () => {
  console.log(`ADM API running on http://localhost:${port}`);
});
