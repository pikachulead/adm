import type { LambdaEvent, LambdaResponse } from './lambda-utils.js';
import { jsonResponse, parseBody, errorResponse } from './lambda-utils.js';
import { validateAuth } from '../middleware/auth.js';
import { validateEntityType, validateUuid } from '../middleware/validation.js';
import { createRepository } from '../repositories/index.js';
import type { EntityType } from '../types/entities.js';

interface ExpandRequest {
  nodeType: string;
  nodeId: string;
}

export async function handler(event: LambdaEvent): Promise<LambdaResponse> {
  if (event.requestContext?.http?.method === 'OPTIONS') {
    return jsonResponse(204, null);
  }

  const authError = validateAuth(event);
  if (authError) return authError;

  const body = parseBody<ExpandRequest>(event);
  if (!body) return errorResponse(400, 'Request body is required');

  const typeError = validateEntityType(body.nodeType);
  if (typeError) return typeError;

  const idError = validateUuid(body.nodeId, 'nodeId');
  if (idError) return idError;

  try {
    const repository = createRepository();
    const result = await repository.expandNode(
      body.nodeType as EntityType,
      body.nodeId,
    );
    return jsonResponse(200, result);
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Internal server error';
    return errorResponse(500, message);
  }
}
