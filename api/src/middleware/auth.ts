import type { LambdaEvent, LambdaResponse } from '../handlers/lambda-utils.js';
import { errorResponse } from '../handlers/lambda-utils.js';

export function validateAuth(event: LambdaEvent): LambdaResponse | null {
  const username = process.env.ADM_API_USER;
  const password = process.env.ADM_API_PASSWORD;

  if (!username || !password) return null;

  const authHeader = event.headers?.authorization ?? event.headers?.Authorization;

  if (!authHeader) {
    return errorResponse(401, 'Authorization header is required');
  }

  if (!authHeader.startsWith('Basic ')) {
    return errorResponse(401, 'Basic authentication is required');
  }

  const encoded = authHeader.slice(6);
  let decoded: string;
  try {
    decoded = Buffer.from(encoded, 'base64').toString('utf-8');
  } catch {
    return errorResponse(401, 'Invalid authorization encoding');
  }

  const separatorIndex = decoded.indexOf(':');
  if (separatorIndex === -1) {
    return errorResponse(401, 'Invalid credentials format');
  }

  const providedUser = decoded.slice(0, separatorIndex);
  const providedPass = decoded.slice(separatorIndex + 1);

  if (providedUser !== username || providedPass !== password) {
    return errorResponse(403, 'Invalid credentials');
  }

  return null;
}
