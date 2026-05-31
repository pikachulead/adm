#!/usr/bin/env node
import * as cdk from 'aws-cdk-lib';
import { DatabaseStack } from '../lib/database-stack.js';
import { ApiStack } from '../lib/api-stack.js';
import { FrontendStack } from '../lib/frontend-stack.js';

const app = new cdk.App();

const envName = app.node.tryGetContext('env') ?? 'dev';
const llmProvider = app.node.tryGetContext('llmProvider') ?? 'groq';
const llmModel = app.node.tryGetContext('llmModel') ?? 'llama-3.3-70b-versatile';

const env: cdk.Environment = {
  account: process.env.CDK_DEFAULT_ACCOUNT,
  region: process.env.CDK_DEFAULT_REGION ?? 'us-east-1',
};

const dbStack = new DatabaseStack(app, `Adm-${envName}-Database`, {
  envName,
  env,
});

new ApiStack(app, `Adm-${envName}-Api`, {
  envName,
  env,
  dbSecret: dbStack.dbSecret,
  dbEndpoint: dbStack.dbEndpoint,
  dbPort: dbStack.dbPort,
  dbName: dbStack.dbName,
  llmProvider,
  llmModel,
});

new FrontendStack(app, `Adm-${envName}-Frontend`, {
  envName,
  env,
});
