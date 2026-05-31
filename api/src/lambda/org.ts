import { resolveEnv } from './env.js';
import { handler as orgHandler } from '../handlers/org.js';

export const handler = async (event: unknown) => {
  await resolveEnv();
  return orgHandler(event as Parameters<typeof orgHandler>[0]);
};
