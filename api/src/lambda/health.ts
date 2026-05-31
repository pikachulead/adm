import { resolveEnv } from './env.js';
import { handler as healthHandler } from '../handlers/health.js';

export const handler = async (event: unknown) => {
  await resolveEnv();
  return healthHandler(event as Parameters<typeof healthHandler>[0]);
};
