import { describe, it, expect, afterAll } from 'vitest';
import { handler as expandHandler } from '../../handlers/expand.js';
import { handler as searchHandler } from '../../handlers/search.js';
import { closePool } from '../../repositories/postgresql/pg-pool.js';
import type { LambdaEvent } from '../../handlers/lambda-utils.js';

afterAll(async () => {
  await closePool();
});

function postEvent(body: unknown): LambdaEvent {
  return {
    body: JSON.stringify(body),
    headers: {},
    requestContext: { http: { method: 'POST', path: '/test' } },
  };
}

describe('validation E2E', () => {
  it('rejects expand with invalid entity type', async () => {
    const response = await expandHandler(
      postEvent({ nodeType: 'invalid_type', nodeId: '10000000-0000-0000-0000-000000000001' }),
    );
    expect(response.statusCode).toBe(400);
    const body = JSON.parse(response.body);
    expect(body.error).toContain('Invalid entity type');
  });

  it('rejects expand with invalid UUID', async () => {
    const response = await expandHandler(
      postEvent({ nodeType: 'domain', nodeId: 'not-a-uuid' }),
    );
    expect(response.statusCode).toBe(400);
    const body = JSON.parse(response.body);
    expect(body.error).toContain('UUID');
  });

  it('rejects expand with missing body', async () => {
    const response = await expandHandler({ body: null, headers: {} });
    expect(response.statusCode).toBe(400);
  });

  it('rejects search with empty query', async () => {
    const response = await searchHandler(postEvent({ query: '' }));
    expect(response.statusCode).toBe(400);
    const body = JSON.parse(response.body);
    expect(body.error).toContain('query');
  });

  it('rejects search with missing body', async () => {
    const response = await searchHandler({ body: null, headers: {} });
    expect(response.statusCode).toBe(400);
  });

  it('handles OPTIONS preflight on expand', async () => {
    const response = await expandHandler({
      body: null,
      headers: {},
      requestContext: { http: { method: 'OPTIONS', path: '/api/expand' } },
    });
    expect(response.statusCode).toBe(204);
  });

  it('handles base64-encoded body', async () => {
    const encoded = Buffer.from(
      JSON.stringify({ nodeType: 'domain', nodeId: '10000000-0000-0000-0000-000000000001' }),
    ).toString('base64');

    const response = await expandHandler({
      body: encoded,
      isBase64Encoded: true,
      headers: {},
      requestContext: { http: { method: 'POST', path: '/api/expand' } },
    });
    expect(response.statusCode).toBe(200);
    const body = JSON.parse(response.body);
    expect(body.nodes).toHaveLength(9);
  });

  it('returns CORS headers on all responses', async () => {
    const response = await expandHandler(
      postEvent({ nodeType: 'domain', nodeId: '10000000-0000-0000-0000-000000000001' }),
    );
    expect(response.headers['Access-Control-Allow-Origin']).toBe('*');
    expect(response.headers['Content-Type']).toBe('application/json');
  });
});
