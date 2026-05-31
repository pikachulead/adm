import type { LambdaEvent, LambdaResponse } from '../handlers/lambda-utils.js';
import { errorResponse } from '../handlers/lambda-utils.js';

export function withTimeout(
  handler: (event: LambdaEvent) => Promise<LambdaResponse>,
  timeoutMs: number,
): (event: LambdaEvent) => Promise<LambdaResponse> {
  return async (event: LambdaEvent): Promise<LambdaResponse> => {
    const timeoutPromise = new Promise<LambdaResponse>((resolve) => {
      setTimeout(
        () => resolve(errorResponse(504, 'Request timed out')),
        timeoutMs,
      );
    });

    return Promise.race([handler(event), timeoutPromise]);
  };
}
