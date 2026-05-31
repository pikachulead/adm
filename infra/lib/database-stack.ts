import * as cdk from 'aws-cdk-lib';
import * as ec2 from 'aws-cdk-lib/aws-ec2';
import * as rds from 'aws-cdk-lib/aws-rds';
import * as secretsmanager from 'aws-cdk-lib/aws-secretsmanager';
import type { Construct } from 'constructs';

export interface DatabaseStackProps extends cdk.StackProps {
  readonly envName: string;
}

export class DatabaseStack extends cdk.Stack {
  public readonly dbSecret: secretsmanager.ISecret;
  public readonly dbEndpoint: string;
  public readonly dbPort: string;
  public readonly dbName: string;
  public readonly securityGroup: ec2.ISecurityGroup;

  constructor(scope: Construct, id: string, props: DatabaseStackProps) {
    super(scope, id, props);

    const { envName } = props;

    const vpc = new ec2.Vpc(this, 'AdmVpc', {
      maxAzs: 2,
      natGateways: 0,
      subnetConfiguration: [
        {
          name: 'public',
          subnetType: ec2.SubnetType.PUBLIC,
          cidrMask: 24,
        },
      ],
    });

    const dbSecurityGroup = new ec2.SecurityGroup(this, 'DbSecurityGroup', {
      vpc,
      description: 'ADM Aurora PostgreSQL security group',
      allowAllOutbound: true,
    });

    dbSecurityGroup.addIngressRule(
      ec2.Peer.anyIpv4(),
      ec2.Port.tcp(5432),
      'Allow PostgreSQL access',
    );

    this.securityGroup = dbSecurityGroup;

    const dbCredentials = new secretsmanager.Secret(this, 'DbCredentials', {
      secretName: `adm/${envName}/db-credentials`,
      generateSecretString: {
        secretStringTemplate: JSON.stringify({ username: 'adm_user' }),
        generateStringKey: 'password',
        excludePunctuation: true,
        passwordLength: 32,
      },
    });

    this.dbSecret = dbCredentials;
    this.dbName = 'adm';

    const cluster = new rds.DatabaseCluster(this, 'AdmAuroraCluster', {
      engine: rds.DatabaseClusterEngine.auroraPostgres({
        version: rds.AuroraPostgresEngineVersion.VER_16_4,
      }),
      credentials: rds.Credentials.fromSecret(dbCredentials),
      defaultDatabaseName: this.dbName,
      serverlessV2MinCapacity: 0.5,
      serverlessV2MaxCapacity: 2,
      writer: rds.ClusterInstance.serverlessV2('writer', {
        publiclyAccessible: true,
      }),
      vpc,
      vpcSubnets: { subnetType: ec2.SubnetType.PUBLIC },
      securityGroups: [dbSecurityGroup],
      removalPolicy: cdk.RemovalPolicy.DESTROY,
      storageEncrypted: true,
    });

    this.dbEndpoint = cluster.clusterEndpoint.hostname;
    this.dbPort = cluster.clusterEndpoint.port.toString();

    new cdk.CfnOutput(this, 'DbEndpoint', {
      value: this.dbEndpoint,
      description: 'Aurora cluster endpoint',
    });

    new cdk.CfnOutput(this, 'DbSecretArn', {
      value: dbCredentials.secretArn,
      description: 'Database credentials secret ARN',
    });
  }
}
