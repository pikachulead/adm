import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import { PgArchitectureRepository } from '../postgresql/pg-repository.js';
import { getPool, closePool } from '../postgresql/pg-pool.js';
import type pg from 'pg';

let pool: pg.Pool;
let repo: PgArchitectureRepository;

beforeAll(() => {
  pool = getPool();
  repo = new PgArchitectureRepository(pool);
});

afterAll(async () => {
  await closePool();
});

describe('searchByKeyword', () => {
  it('finds FNOL-related capabilities', async () => {
    const results = await repo.searchByKeyword('First Notice of Loss');
    expect(results.length).toBeGreaterThan(0);
    expect(results.some((r) => r.name.includes('First Notice of Loss'))).toBe(true);
  });

  it('finds systems by partial name', async () => {
    const results = await repo.searchByKeyword('Claims Core');
    expect(results.some((r) => r.name === 'Claims Core Platform')).toBe(true);
  });

  it('returns empty array for non-existent keyword', async () => {
    const results = await repo.searchByKeyword('xyznonexistent123');
    expect(results).toEqual([]);
  });
});

describe('getFullPath', () => {
  it('returns full path for Claims domain', async () => {
    const rows = await repo.getFullPath({ domain_name: 'Claims' });
    expect(rows.length).toBeGreaterThan(0);
    expect(rows[0].domain_name).toBe('Claims');
    const withTech = rows.filter((r) => r.technology_name !== null);
    expect(withTech.length).toBeGreaterThan(0);
  });

  it('returns paths across all domains when no filter', async () => {
    const rows = await repo.getFullPath();
    const domains = new Set(rows.map((r) => r.domain_name));
    expect(domains.size).toBe(4);
  });

  it('filters by capability name', async () => {
    const rows = await repo.getFullPath({ capability_name: 'First Notice' });
    expect(rows.length).toBeGreaterThan(0);
    expect(rows.every((r) => r.capability_name.includes('First Notice'))).toBe(true);
  });
});

describe('getReversePath', () => {
  it('finds impact of Java across multiple domains', async () => {
    const rows = await repo.getReversePath('Java');
    expect(rows.length).toBeGreaterThan(0);
    const domains = new Set(rows.map((r) => r.domain_name).filter(Boolean));
    expect(domains.size).toBeGreaterThanOrEqual(2);
  });

  it('includes system owner information', async () => {
    const rows = await repo.getReversePath('Java');
    const withOwner = rows.filter((r) => r.owner_team !== null);
    expect(withOwner.length).toBeGreaterThan(0);
  });
});

describe('expandNode', () => {
  it('expands Claims domain to 9 capabilities', async () => {
    const claimsDomainId = '10000000-0000-0000-0000-000000000001';
    const result = await repo.expandNode('domain', claimsDomainId);
    expect(result.nodes.length).toBe(9);
    expect(result.edges.length).toBe(9);
    expect(result.nodes.every((n) => n.type === 'capability')).toBe(true);
    expect(result.edges.every((e) => e.label === 'owns')).toBe(true);
  });

  it('expands Capture FNOL capability to processes', async () => {
    const fnolCapabilityId = '20000000-0000-0000-0000-000000000002';
    const result = await repo.expandNode('capability', fnolCapabilityId);
    expect(result.nodes.some((n) => n.type === 'process')).toBe(true);
    expect(result.nodes.some((n) => n.label === 'Submit First Notice of Loss')).toBe(true);
  });

  it('expands Claims Core Platform to technologies and data entities', async () => {
    const claimsCoreId = '60000000-0000-0000-0000-000000000001';
    const result = await repo.expandNode('system', claimsCoreId);
    expect(result.nodes.some((n) => n.type === 'technology')).toBe(true);
    expect(result.nodes.some((n) => n.type === 'data_entity')).toBe(true);
    expect(result.nodes.some((n) => n.label === 'Java')).toBe(true);
  });
});

describe('findSimilar', () => {
  it('finds similar capabilities for fuzzy input', async () => {
    const results = await repo.findSimilar('capability', 'Claim Processing');
    expect(results.length).toBeGreaterThan(0);
  });

  it('returns exact matches with high similarity', async () => {
    const results = await repo.findSimilar('system', 'Claims Core Platform');
    expect(results.length).toBeGreaterThan(0);
    expect(results[0].name).toBe('Claims Core Platform');
    expect(results[0].similarity).toBeGreaterThan(0.5);
  });
});

describe('listEntities', () => {
  it('lists all 4 business domains', async () => {
    const domains = await repo.listEntities('domain');
    expect(domains.length).toBe(4);
  });

  it('lists technologies', async () => {
    const techs = await repo.listEntities('technology');
    expect(techs.length).toBeGreaterThan(0);
  });
});

describe('getMetadata', () => {
  it('returns metadata rows', async () => {
    const metadata = await repo.getMetadata();
    expect(metadata.length).toBeGreaterThan(0);
  });

  it('filters by metadata type', async () => {
    const entities = await repo.getMetadata(['ENTITY']);
    expect(entities.length).toBeGreaterThan(0);
    expect(entities.every((m) => m.metadata_type === 'ENTITY')).toBe(true);
  });
});

describe('healthCheck', () => {
  it('returns true when database is connected', async () => {
    const healthy = await repo.healthCheck();
    expect(healthy).toBe(true);
  });
});
