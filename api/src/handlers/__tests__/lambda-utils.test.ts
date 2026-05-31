import { describe, it, expect } from 'vitest';
import { jsonResponse, parseBody, errorResponse } from '../lambda-utils.js';
import type { LambdaEvent } from '../lambda-utils.js';

describe('lambda-utils', () => {
  describe('jsonResponse', () => {
    it('creates a response with JSON body and CORS headers', () => {
      const response = jsonResponse(200, { key: 'value' });
      expect(response.statusCode).toBe(200);
      expect(JSON.parse(response.body)).toEqual({ key: 'value' });
      expect(response.headers['Content-Type']).toBe('application/json');
      expect(response.headers['Access-Control-Allow-Origin']).toBe('*');
    });
  });

  describe('parseBody', () => {
    it('parses JSON body', () => {
      const event: LambdaEvent = { body: '{"query":"test"}' };
      const result = parseBody<{ query: string }>(event);
      expect(result).toEqual({ query: 'test' });
    });

    it('returns null for empty body', () => {
      const event: LambdaEvent = { body: null };
      expect(parseBody(event)).toBeNull();
    });

    it('returns null for invalid JSON', () => {
      const event: LambdaEvent = { body: 'not json' };
      expect(parseBody(event)).toBeNull();
    });

    it('handles base64 encoded body', () => {
      const encoded = Buffer.from('{"query":"test"}').toString('base64');
      const event: LambdaEvent = { body: encoded, isBase64Encoded: true };
      const result = parseBody<{ query: string }>(event);
      expect(result).toEqual({ query: 'test' });
    });
  });

  describe('errorResponse', () => {
    it('creates an error response', () => {
      const response = errorResponse(400, 'Bad request');
      expect(response.statusCode).toBe(400);
      expect(JSON.parse(response.body)).toEqual({ error: 'Bad request' });
    });
  });
});
