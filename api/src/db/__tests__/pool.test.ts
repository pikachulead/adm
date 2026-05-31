import { describe, it, expect, afterAll } from 'vitest';
import { getPool, closePool } from '../pool.js';

describe('database connectivity', () => {
  afterAll(async () => {
    await closePool();
  });

  it('connects to PostgreSQL and verifies adm schema exists', async () => {
    const pool = getPool();
    const result = await pool.query('SELECT COUNT(*)::int AS count FROM business_domains');
    expect(result.rows[0].count).toBe(4);
  });

  it('verifies pg_trgm extension is available', async () => {
    const pool = getPool();
    const result = await pool.query(
      "SELECT EXISTS(SELECT 1 FROM pg_extension WHERE extname = 'pg_trgm') AS installed"
    );
    expect(result.rows[0].installed).toBe(true);
  });

  it('verifies all entity tables have data', async () => {
    const pool = getPool();
    const tables = [
      'business_domains',
      'business_capabilities',
      'business_processes',
      'business_systems',
      'technology_components',
      'business_data_entities',
    ];

    for (const table of tables) {
      const result = await pool.query(`SELECT COUNT(*)::int AS count FROM ${table}`);
      expect(result.rows[0].count).toBeGreaterThan(0);
    }
  });
});
