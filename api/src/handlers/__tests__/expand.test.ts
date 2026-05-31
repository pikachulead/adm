import { describe, it, expect, afterAll } from 'vitest';
import { handler } from '../expand.js';
import { closePool } from '../../repositories/postgresql/pg-pool.js';
import type { LambdaEvent } from '../lambda-utils.js';

afterAll(async () => {
  await closePool();
});

function makeEvent(body: unknown): LambdaEvent {
  return {
    body: JSON.stringify(body),
    headers: {},
    requestContext: { http: { method: 'POST', path: '/api/expand' } },
  };
}

describe('expand handler', () => {
  it('expands Claims domain to 9 capabilities', async () => {
    const response = await handler(
      makeEvent({
        nodeType: 'domain',
        nodeId: '10000000-0000-0000-0000-000000000001',
      }),
    );
    expect(response.statusCode).toBe(200);
    const body = JSON.parse(response.body);
    expect(body.nodes).toHaveLength(9);
    expect(body.edges).toHaveLength(9);
  });

  it('returns 400 for invalid entity type', async () => {
    const response = await handler(
      makeEvent({ nodeType: 'invalid', nodeId: '10000000-0000-0000-0000-000000000001' }),
    );
    expect(response.statusCode).toBe(400);
  });

  it('returns 400 for invalid UUID', async () => {
    const response = await handler(
      makeEvent({ nodeType: 'domain', nodeId: 'not-a-uuid' }),
    );
    expect(response.statusCode).toBe(400);
  });

  it('returns 400 for missing body', async () => {
    const response = await handler({ body: null, headers: {} });
    expect(response.statusCode).toBe(400);
  });

  it('handles OPTIONS preflight', async () => {
    const response = await handler({
      body: null,
      headers: {},
      requestContext: { http: { method: 'OPTIONS', path: '/api/expand' } },
    });
    expect(response.statusCode).toBe(204);
  });
});
