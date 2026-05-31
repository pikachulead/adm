import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import { validateAuth } from '../auth.js';
import type { LambdaEvent } from '../../handlers/lambda-utils.js';

function makeEvent(authHeader?: string): LambdaEvent {
  return {
    body: null,
    headers: authHeader ? { authorization: authHeader } : {},
  };
}

function encode(user: string, pass: string): string {
  return Buffer.from(`${user}:${pass}`).toString('base64');
}

describe('auth middleware', () => {
  const originalUser = process.env.ADM_API_USER;
  const originalPass = process.env.ADM_API_PASSWORD;

  afterEach(() => {
    if (originalUser !== undefined) process.env.ADM_API_USER = originalUser;
    else delete process.env.ADM_API_USER;
    if (originalPass !== undefined) process.env.ADM_API_PASSWORD = originalPass;
    else delete process.env.ADM_API_PASSWORD;
  });

  it('passes when no credentials are configured', () => {
    delete process.env.ADM_API_USER;
    delete process.env.ADM_API_PASSWORD;
    const result = validateAuth(makeEvent());
    expect(result).toBeNull();
  });

  it('rejects when no auth header provided but credentials are configured', () => {
    process.env.ADM_API_USER = 'admin';
    process.env.ADM_API_PASSWORD = 'secret';
    const result = validateAuth(makeEvent());
    expect(result).not.toBeNull();
    expect(result!.statusCode).toBe(401);
  });

  it('rejects non-Basic auth scheme', () => {
    process.env.ADM_API_USER = 'admin';
    process.env.ADM_API_PASSWORD = 'secret';
    const result = validateAuth(makeEvent('Bearer token123'));
    expect(result).not.toBeNull();
    expect(result!.statusCode).toBe(401);
  });

  it('rejects wrong credentials', () => {
    process.env.ADM_API_USER = 'admin';
    process.env.ADM_API_PASSWORD = 'secret';
    const result = validateAuth(makeEvent(`Basic ${encode('admin', 'wrong')}`));
    expect(result).not.toBeNull();
    expect(result!.statusCode).toBe(403);
  });

  it('passes with correct credentials', () => {
    process.env.ADM_API_USER = 'admin';
    process.env.ADM_API_PASSWORD = 'secret';
    const result = validateAuth(makeEvent(`Basic ${encode('admin', 'secret')}`));
    expect(result).toBeNull();
  });

  it('handles password containing colons', () => {
    process.env.ADM_API_USER = 'admin';
    process.env.ADM_API_PASSWORD = 'pass:with:colons';
    const result = validateAuth(makeEvent(`Basic ${encode('admin', 'pass:with:colons')}`));
    expect(result).toBeNull();
  });
});
