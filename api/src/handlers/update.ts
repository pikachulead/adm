import type { LambdaEvent, LambdaResponse } from './lambda-utils.js';
import { jsonResponse, parseBody, errorResponse } from './lambda-utils.js';
import { validateAuth } from '../middleware/auth.js';
import { validateRequiredString } from '../middleware/validation.js';
import { createAgentService } from '../agent/agent-service.js';
import { createLlmProvider } from '../llm/index.js';
import { createRepository } from '../repositories/index.js';

interface UpdateRequest {
  request: string;
}

export async function handler(event: LambdaEvent): Promise<LambdaResponse> {
  if (event.requestContext?.http?.method === 'OPTIONS') {
    return jsonResponse(204, null);
  }

  const authError = validateAuth(event);
  if (authError) return authError;

  const body = parseBody<UpdateRequest>(event);
  if (!body) return errorResponse(400, 'Request body is required');

  const requestError = validateRequiredString(body.request, 'request');
  if (requestError) return requestError;

  try {
    const llm = createLlmProvider();
    const repository = createRepository();
    const agent = createAgentService(llm, repository);
    const result = await agent.run(body.request);
    return jsonResponse(200, result);
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Internal server error';
    return errorResponse(502, message);
  }
}
