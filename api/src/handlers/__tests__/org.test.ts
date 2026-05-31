import { describe, it, expect, afterAll } from 'vitest';
import { handler } from '../org.js';
import { closePool } from '../../repositories/postgresql/pg-pool.js';
import type { LambdaEvent } from '../lambda-utils.js';

afterAll(async () => {
  await closePool();
});

describe('org handler', () => {
  it('returns full organization graph with all 4 domains', async () => {
    const event: LambdaEvent = {
      body: null,
      headers: {},
      requestContext: { http: { method: 'GET', path: '/api/org' } },
    };
    const response = await handler(event);
    expect(response.statusCode).toBe(200);

    const body = JSON.parse(response.body);
    expect(body.nodes.length).toBeGreaterThan(0);
    expect(body.edges.length).toBeGreaterThan(0);

    const domainNodes = body.nodes.filter((n: { type: string }) => n.type === 'domain');
    expect(domainNodes).toHaveLength(4);

    const types = new Set(body.nodes.map((n: { type: string }) => n.type));
    expect(types).toContain('domain');
    expect(types).toContain('capability');
    expect(types).toContain('process');
    expect(types).toContain('system');
    expect(types).toContain('technology');
  });

  it('handles OPTIONS preflight', async () => {
    const response = await handler({
      body: null,
      headers: {},
      requestContext: { http: { method: 'OPTIONS', path: '/api/org' } },
    });
    expect(response.statusCode).toBe(204);
  });
});
