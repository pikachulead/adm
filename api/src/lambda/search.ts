import { resolveEnv } from './env.js';
import { handler as searchHandler } from '../handlers/search.js';

export const handler = async (event: unknown) => {
  await resolveEnv();
  return searchHandler(event as Parameters<typeof searchHandler>[0]);
};
