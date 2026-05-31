import * as cdk from 'aws-cdk-lib';
import * as lambda from 'aws-cdk-lib/aws-lambda';
import * as nodejs from 'aws-cdk-lib/aws-lambda-nodejs';
import * as secretsmanager from 'aws-cdk-lib/aws-secretsmanager';
import * as path from 'path';
import { fileURLToPath } from 'url';
import type { Construct } from 'constructs';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

export interface ApiStackProps extends cdk.StackProps {
  readonly envName: string;
  readonly dbSecret: secretsmanager.ISecret;
  readonly dbEndpoint: string;
  readonly dbPort: string;
  readonly dbName: string;
  readonly llmProvider: string;
  readonly llmModel: string;
}

const HANDLER_NAMES = ['search', 'expand', 'update', 'health', 'org'] as const;

export class ApiStack extends cdk.Stack {
  public readonly functionUrls: Record<string, lambda.FunctionUrl> = {};

  constructor(scope: Construct, id: string, props: ApiStackProps) {
    super(scope, id, props);

    const {
      envName,
      dbSecret,
      dbEndpoint,
      dbPort,
      dbName,
      llmProvider,
      llmModel,
    } = props;

    const llmSecret = new secretsmanager.Secret(this, 'LlmApiKey', {
      secretName: `adm/${envName}/llm-api-key`,
      secretStringValue: cdk.SecretValue.unsafePlainText('REPLACE_ME'),
    });

    const apiHandlerDir = path.join(__dirname, '../../api/src/lambda');

    const commonEnv: Record<string, string> = {
      NODE_OPTIONS: '--enable-source-maps',
      DB_SECRET_ARN: dbSecret.secretArn,
      DB_HOST: dbEndpoint,
      DB_PORT: dbPort,
      DB_NAME: dbName,
      DB_PROVIDER: 'postgresql',
      LLM_SECRET_ARN: llmSecret.secretArn,
      LLM_PROVIDER: llmProvider,
      LLM_MODEL: llmModel,
    };

    for (const name of HANDLER_NAMES) {
      const timeout = name === 'search' || name === 'update' ? 60 : 10;

      const fn = new nodejs.NodejsFunction(this, `${capitalize(name)}Function`, {
        functionName: `adm-${envName}-${name}`,
        runtime: lambda.Runtime.NODEJS_22_X,
        entry: path.join(apiHandlerDir, `${name}.ts`),
        handler: 'handler',
        timeout: cdk.Duration.seconds(timeout),
        memorySize: 256,
        environment: commonEnv,
        bundling: {
          format: nodejs.OutputFormat.ESM,
          target: 'node22',
          sourceMap: true,
          minify: true,
          externalModules: ['@aws-sdk/*'],
        },
      });

      dbSecret.grantRead(fn);
      llmSecret.grantRead(fn);

      const fnUrl = fn.addFunctionUrl({
        authType: lambda.FunctionUrlAuthType.NONE,
        cors: {
          allowedOrigins: ['*'],
          allowedMethods: [lambda.HttpMethod.GET, lambda.HttpMethod.POST],
          allowedHeaders: ['Content-Type', 'Authorization'],
        },
      });

      this.functionUrls[name] = fnUrl;

      new cdk.CfnOutput(this, `${capitalize(name)}Url`, {
        value: fnUrl.url,
        description: `${name} Lambda Function URL`,
      });
    }

    new cdk.CfnOutput(this, 'LlmSecretArn', {
      value: llmSecret.secretArn,
      description: 'LLM API key secret ARN — update this secret with your actual key',
    });
  }
}

function capitalize(s: string): string {
  return s.charAt(0).toUpperCase() + s.slice(1);
}
