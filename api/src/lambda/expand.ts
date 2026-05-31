import { resolveEnv } from './env.js';
import { handler as expandHandler } from '../handlers/expand.js';

export const handler = async (event: unknown) => {
  await resolveEnv();
  return expandHandler(event as Parameters<typeof expandHandler>[0]);
};
