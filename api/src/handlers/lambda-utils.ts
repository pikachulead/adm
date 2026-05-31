export interface LambdaEvent {
  body?: string | null;
  headers?: Record<string, string | undefined>;
  requestContext?: {
    http?: {
      method?: string;
      path?: string;
    };
  };
  rawPath?: string;
  rawQueryString?: string;
  queryStringParameters?: Record<string, string | undefined>;
  isBase64Encoded?: boolean;
}

export interface LambdaResponse {
  statusCode: number;
  headers: Record<string, string>;
  body: string;
}

const CORS_HEADERS: Record<string, string> = {
  'Content-Type': 'application/json',
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization',
};

export function jsonResponse(statusCode: number, data: unknown): LambdaResponse {
  return {
    statusCode,
    headers: CORS_HEADERS,
    body: JSON.stringify(data),
  };
}

export function parseBody<T>(event: LambdaEvent): T | null {
  if (!event.body) return null;
  try {
    const raw = event.isBase64Encoded
      ? Buffer.from(event.body, 'base64').toString('utf-8')
      : event.body;
    return JSON.parse(raw) as T;
  } catch {
    return null;
  }
}

export function errorResponse(statusCode: number, message: string): LambdaResponse {
  return jsonResponse(statusCode, { error: message });
}
