import { describe, it, expect, vi, beforeEach } from 'vitest';
import { searchArchitecture, expandNode, healthCheck } from '@/api/client.js';

const mockFetch = vi.fn();
vi.stubGlobal('fetch', mockFetch);

beforeEach(() => {
  mockFetch.mockReset();
});

describe('API client', () => {
  it('sends search request with correct body', async () => {
    mockFetch.mockResolvedValue({
      ok: true,
      json: () => Promise.resolve({ answer: 'test', graph: { nodes: [], edges: [] } }),
    });

    await searchArchitecture('FNOL');

    expect(mockFetch).toHaveBeenCalledWith('/api/search', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ query: 'FNOL' }),
    });
  });

  it('sends expand request with correct body', async () => {
    mockFetch.mockResolvedValue({
      ok: true,
      json: () => Promise.resolve({ nodes: [], edges: [] }),
    });

    await expandNode('domain', 'test-uuid');

    expect(mockFetch).toHaveBeenCalledWith('/api/expand', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ nodeType: 'domain', nodeId: 'test-uuid' }),
    });
  });

  it('sends health check as GET', async () => {
    mockFetch.mockResolvedValue({
      ok: true,
      json: () => Promise.resolve({ status: 'ok', database: 'connected' }),
    });

    await healthCheck();

    expect(mockFetch).toHaveBeenCalledWith('/api/health', {
      method: 'GET',
      headers: { 'Content-Type': 'application/json' },
    });
  });

  it('throws on non-ok response', async () => {
    mockFetch.mockResolvedValue({
      ok: false,
      statusText: 'Bad Request',
      json: () => Promise.resolve({ error: 'Invalid query' }),
    });

    await expect(searchArchitecture('')).rejects.toThrow('Invalid query');
  });
});
