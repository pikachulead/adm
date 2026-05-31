import * as cdk from 'aws-cdk-lib';
import * as s3 from 'aws-cdk-lib/aws-s3';
import * as s3deploy from 'aws-cdk-lib/aws-s3-deployment';
import * as path from 'path';
import { fileURLToPath } from 'url';
import type { Construct } from 'constructs';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

export interface FrontendStackProps extends cdk.StackProps {
  readonly envName: string;
}

export class FrontendStack extends cdk.Stack {
  public readonly bucketUrl: string;

  constructor(scope: Construct, id: string, props: FrontendStackProps) {
    super(scope, id, props);

    const { envName } = props;

    const bucket = new s3.Bucket(this, 'FrontendBucket', {
      bucketName: `adm-${envName}-frontend-${this.account}`,
      websiteIndexDocument: 'index.html',
      websiteErrorDocument: 'index.html',
      publicReadAccess: true,
      blockPublicAccess: new s3.BlockPublicAccess({
        blockPublicAcls: false,
        ignorePublicAcls: false,
        blockPublicPolicy: false,
        restrictPublicBuckets: false,
      }),
      removalPolicy: cdk.RemovalPolicy.DESTROY,
      autoDeleteObjects: true,
    });

    new s3deploy.BucketDeployment(this, 'DeployFrontend', {
      sources: [s3deploy.Source.asset(path.join(__dirname, '../../frontend/dist'))],
      destinationBucket: bucket,
    });

    this.bucketUrl = bucket.bucketWebsiteUrl;

    new cdk.CfnOutput(this, 'FrontendUrl', {
      value: bucket.bucketWebsiteUrl,
      description: 'Frontend website URL',
    });
  }
}
