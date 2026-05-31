import {
  SecretsManagerClient,
  GetSecretValueCommand,
} from '@aws-sdk/client-secrets-manager';

let resolved = false;

export async function resolveEnv(): Promise<void> {
  if (resolved) return;

  const client = new SecretsManagerClient({});

  const dbSecretArn = process.env.DB_SECRET_ARN;
  if (dbSecretArn && !process.env.DATABASE_URL) {
    const response = await client.send(
      new GetSecretValueCommand({ SecretId: dbSecretArn }),
    );
    const secret = JSON.parse(response.SecretString ?? '{}');
    const host = process.env.DB_HOST ?? 'localhost';
    const port = process.env.DB_PORT ?? '5432';
    const dbName = process.env.DB_NAME ?? 'adm';
    process.env.DATABASE_URL = `postgresql://${secret.username}:${secret.password}@${host}:${port}/${dbName}`;
  }

  const llmSecretArn = process.env.LLM_SECRET_ARN;
  if (llmSecretArn && !process.env.LLM_API_KEY) {
    const response = await client.send(
      new GetSecretValueCommand({ SecretId: llmSecretArn }),
    );
    const secret = JSON.parse(response.SecretString ?? '{}');
    process.env.LLM_API_KEY = secret.apiKey ?? secret.api_key ?? '';
  }

  resolved = true;
}
