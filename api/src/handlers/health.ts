import type { LambdaEvent, LambdaResponse } from './lambda-utils.js';
import { jsonResponse, errorResponse } from './lambda-utils.js';
import { createRepository } from '../repositories/index.js';

export async function handler(_event: LambdaEvent): Promise<LambdaResponse> {
  try {
    const repository = createRepository();
    const dbHealthy = await repository.healthCheck();
    if (!dbHealthy) {
      return errorResponse(503, 'Database is not available');
    }
    return jsonResponse(200, { status: 'ok', database: 'connected' });
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Health check failed';
    return errorResponse(503, message);
  }
}
