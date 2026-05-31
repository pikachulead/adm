import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import { executeTool } from '../tool-executor.js';
import { PgArchitectureRepository } from '../../repositories/postgresql/pg-repository.js';
import { getPool, closePool } from '../../repositories/postgresql/pg-pool.js';
import type { IArchitectureRepository } from '../../repositories/interfaces.js';

let repo: IArchitectureRepository;

beforeAll(() => {
  repo = new PgArchitectureRepository(getPool());
});

afterAll(async () => {
  await closePool();
});

describe('tool executor', () => {
  it('executes search_architecture and returns results', async () => {
    const result = await executeTool('search_architecture', { keyword: 'First Notice' }, repo);
    const data = result.data as Array<{ name: string }>;
    expect(data.length).toBeGreaterThan(0);
  });

  it('executes get_full_path with domain filter and returns graph', async () => {
    const result = await executeTool(
      'get_full_path',
      { domain_name: 'Claims' },
      repo,
    );
    expect(result.graph).toBeDefined();
    expect(result.graph!.nodes.length).toBeGreaterThan(0);
    expect(result.graph!.edges.length).toBeGreaterThan(0);
  });

  it('executes get_reverse_impact and returns graph', async () => {
    const result = await executeTool(
      'get_reverse_impact',
      { technology_name: 'Java' },
      repo,
    );
    expect(result.graph).toBeDefined();
    expect(result.graph!.nodes.some((n) => n.type === 'technology')).toBe(true);
    expect(result.graph!.nodes.some((n) => n.type === 'system')).toBe(true);
  });

  it('executes expand_node for Claims domain', async () => {
    const result = await executeTool(
      'expand_node',
      { node_type: 'domain', node_id: '10000000-0000-0000-0000-000000000001' },
      repo,
    );
    expect(result.graph).toBeDefined();
    expect(result.graph!.nodes.length).toBe(9);
  });

  it('executes list_entities for domains', async () => {
    const result = await executeTool(
      'list_entities',
      { entity_type: 'domain' },
      repo,
    );
    const data = result.data as Array<{ domain_name: string }>;
    expect(data.length).toBe(4);
  });

  it('executes suggest_similar for fuzzy matching', async () => {
    const result = await executeTool(
      'suggest_similar',
      { entity_type: 'capability', name: 'First Notice' },
      repo,
    );
    const data = result.data as Array<{ name: string; similarity: number }>;
    expect(data.length).toBeGreaterThan(0);
  });

  it('returns error for unknown tool', async () => {
    const result = await executeTool('nonexistent_tool', {}, repo);
    expect(result.data).toHaveProperty('error');
  });
});
