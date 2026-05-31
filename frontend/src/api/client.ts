import type { SearchResponse, ExpandResponse, EntityType } from '@/types/index.js';

const BASE_URL = '/api';

async function request<T>(path: string, body?: unknown): Promise<T> {
  const options: RequestInit = {
    method: body ? 'POST' : 'GET',
    headers: { 'Content-Type': 'application/json' },
  };
  if (body) {
    options.body = JSON.stringify(body);
  }
  const response = await fetch(`${BASE_URL}${path}`, options);

  if (!response.ok) {
    const error = await response.json().catch(() => ({ error: response.statusText }));
    throw new Error((error as { error: string }).error ?? response.statusText);
  }

  return response.json() as Promise<T>;
}

export function searchArchitecture(query: string): Promise<SearchResponse> {
  return request<SearchResponse>('/search', { query });
}

export function expandNode(nodeType: EntityType, nodeId: string): Promise<ExpandResponse> {
  return request<ExpandResponse>('/expand', { nodeType, nodeId });
}

export function updatePortfolio(requestText: string): Promise<SearchResponse> {
  return request<SearchResponse>('/update', { request: requestText });
}

export function healthCheck(): Promise<{ status: string; database: string }> {
  return request('/health');
}
