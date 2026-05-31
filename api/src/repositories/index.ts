import type { IArchitectureRepository } from './interfaces.js';
import { PgArchitectureRepository } from './postgresql/pg-repository.js';
import { getPool } from './postgresql/pg-pool.js';

export function createRepository(): IArchitectureRepository {
  const provider = process.env.DB_PROVIDER ?? 'postgresql';
  switch (provider) {
    case 'postgresql':
      return new PgArchitectureRepository(getPool());
    default:
      throw new Error(`Unknown DB provider: ${provider}`);
  }
}

export type { IArchitectureRepository } from './interfaces.js';
