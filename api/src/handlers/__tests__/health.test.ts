import { describe, it, expect, afterAll } from 'vitest';
import { handler } from '../health.js';
import { closePool } from '../../repositories/postgresql/pg-pool.js';
import type { LambdaEvent } from '../lambda-utils.js';

afterAll(async () => {
  await closePool();
});

describe('health handler', () => {
  it('returns 200 with ok status when database is connected', async () => {
    const event: LambdaEvent = { body: null, headers: {} };
    const response = await handler(event);
    expect(response.statusCode).toBe(200);
    const body = JSON.parse(response.body);
    expect(body.status).toBe('ok');
    expect(body.database).toBe('connected');
  });
});
