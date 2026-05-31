import { describe, it, expect, afterAll } from 'vitest';
import { handler } from '../../handlers/health.js';
import { closePool } from '../../repositories/postgresql/pg-pool.js';

afterAll(async () => {
  await closePool();
});

describe('health flow E2E', () => {
  it('returns healthy status with database connected', async () => {
    const response = await handler({ body: null, headers: {} });

    expect(response.statusCode).toBe(200);
    const body = JSON.parse(response.body);
    expect(body.status).toBe('ok');
    expect(body.database).toBe('connected');
  });
});
