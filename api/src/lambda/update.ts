import { resolveEnv } from './env.js';
import { handler as updateHandler } from '../handlers/update.js';

export const handler = async (event: unknown) => {
  await resolveEnv();
  return updateHandler(event as Parameters<typeof updateHandler>[0]);
};
