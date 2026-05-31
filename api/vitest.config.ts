import { defineConfig } from 'vitest/config';
import path from 'path';

export default defineConfig({
  test: {
    globals: true,
    testTimeout: 30000,
    env: {
      DATABASE_URL: 'postgresql://adm_user:adm_pass@localhost:5432/adm',
      DB_PROVIDER: 'postgresql',
    },
  },
  resolve: {
    alias: {
      '@': path.resolve(__dirname, 'src'),
    },
  },
});
