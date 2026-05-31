import type { LambdaResponse } from '../handlers/lambda-utils.js';
import { errorResponse } from '../handlers/lambda-utils.js';
import type { EntityType } from '../types/entities.js';

const VALID_ENTITY_TYPES: EntityType[] = [
  'domain', 'capability', 'process', 'system', 'technology', 'data_entity',
];

const UUID_PATTERN = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

export function validateRequiredString(value: unknown, fieldName: string): LambdaResponse | null {
  if (typeof value !== 'string' || value.trim().length === 0) {
    return errorResponse(400, `${fieldName} is required and must be a non-empty string`);
  }
  return null;
}

export function validateEntityType(value: unknown): LambdaResponse | null {
  if (!VALID_ENTITY_TYPES.includes(value as EntityType)) {
    return errorResponse(400, `Invalid entity type. Must be one of: ${VALID_ENTITY_TYPES.join(', ')}`);
  }
  return null;
}

export function validateUuid(value: unknown, fieldName: string): LambdaResponse | null {
  if (typeof value !== 'string' || !UUID_PATTERN.test(value)) {
    return errorResponse(400, `${fieldName} must be a valid UUID`);
  }
  return null;
}
