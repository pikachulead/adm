import type { LambdaEvent, LambdaResponse } from './lambda-utils.js';
import { jsonResponse, errorResponse } from './lambda-utils.js';
import { validateAuth } from '../middleware/auth.js';
import { createRepository } from '../repositories/index.js';
import { pathsToGraph } from '../services/graph-transformer.js';

export async function handler(event: LambdaEvent): Promise<LambdaResponse> {
  if (event.requestContext?.http?.method === 'OPTIONS') {
    return jsonResponse(204, null);
  }

  const authError = validateAuth(event);
  if (authError) return authError;

  try {
    const repository = createRepository();
    const rows = await repository.getFullPath();
    const graph = pathsToGraph(rows);
    return jsonResponse(200, graph);
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Internal server error';
    return errorResponse(500, message);
  }
}
