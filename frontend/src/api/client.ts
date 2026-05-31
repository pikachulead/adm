import type { SearchResponse, ExpandResponse, GraphData, EntityType } from '@/types/index.js';

const API_URLS: Record<string, string> = {
  search: import.meta.env.VITE_API_SEARCH_URL ?? '/api/search',
  expand: import.meta.env.VITE_API_EXPAND_URL ?? '/api/expand',
  update: import.meta.env.VITE_API_UPDATE_URL ?? '/api/update',
  org: import.meta.env.VITE_API_ORG_URL ?? '/api/org',
  health: import.meta.env.VITE_API_HEALTH_URL ?? '/api/health',
};

async function request<T>(endpoint: string, body?: unknown): Promise<T> {
  const url = API_URLS[endpoint] ?? `/api${endpoint}`;
  const options: RequestInit = {
    method: body ? 'POST' : 'GET',
    headers: { 'Content-Type': 'application/json' },
  };
  if (body) {
    options.body = JSON.stringify(body);
  }
  const response = await fetch(url, options);

  if (!response.ok) {
    const error = await response.json().catch(() => ({ error: response.statusText }));
    throw new Error((error as { error: string }).error ?? response.statusText);
  }

  return response.json() as Promise<T>;
}

export function searchArchitecture(query: string): Promise<SearchResponse> {
  return request<SearchResponse>('search', { query });
}

export function expandNode(nodeType: EntityType, nodeId: string): Promise<ExpandResponse> {
  return request<ExpandResponse>('expand', { nodeType, nodeId });
}

export function updatePortfolio(requestText: string): Promise<SearchResponse> {
  return request<SearchResponse>('update', { request: requestText });
}

export function fetchOrgGraph(): Promise<GraphData> {
  return request<GraphData>('org');
}

export function healthCheck(): Promise<{ status: string; database: string }> {
  return request('health');
}
