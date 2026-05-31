# ADM AWS Deployment Guide

## Architecture Overview

```
                    ┌─────────────────────────────┐
                    │   S3 Static Website          │
                    │   (React SPA)                │
                    └──────────┬──────────────────┘
                               │ HTTPS
                               ▼
         ┌─────────────────────────────────────────────┐
         │            Lambda Function URLs              │
         │  (no API Gateway — direct HTTPS endpoints)   │
         ├──────────┬──────────┬──────────┬────────────┤
         │ /search  │ /expand  │ /update  │ /org       │
         │ (60s)    │ (10s)    │ (60s)    │ (10s)      │
         └────┬─────┴────┬─────┴────┬─────┴──────┬─────┘
              │          │          │             │
              ▼          ▼          ▼             ▼
         ┌─────────────────────────────────────────────┐
         │   Aurora Serverless v2 PostgreSQL 16         │
         │   (public access, security group restricted) │
         └─────────────────────────────────────────────┘
              │                    │
              ▼                    ▼
         ┌──────────┐       ┌──────────┐
         │ Secrets   │       │ Secrets   │
         │ Manager   │       │ Manager   │
         │ (DB creds)│       │ (LLM key) │
         └──────────┘       └──────────┘
```

## AWS Services Used

| Service | Purpose | Estimated Monthly Cost |
|---|---|---|
| Lambda (5 functions) | API handlers | Pay per request (~$0 for low traffic) |
| Aurora Serverless v2 | PostgreSQL database | ~$0.12/ACU-hour when active, scales to 0.5 ACU min |
| S3 | Frontend static site hosting | < $1 |
| Secrets Manager | DB credentials + LLM API key | $0.80 (2 secrets) |
| VPC (no NAT Gateway) | Network for Aurora | $0 |

**No API Gateway required** — Lambda Function URLs provide direct HTTPS endpoints.

## Prerequisites

- **AWS CLI** — [install guide](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
- **AWS CDK** — installed as project dev dependency (no global install needed)
- **Node.js 22** — [download](https://nodejs.org/)
- **AWS Account** with permissions for: Lambda, RDS, S3, VPC, Secrets Manager, IAM, CloudFormation

### Required IAM Permissions

The deploying user/role needs permissions for:

- `cloudformation:*`
- `lambda:*`
- `rds:*`
- `s3:*`
- `ec2:*` (VPC, subnets, security groups)
- `secretsmanager:*`
- `iam:CreateRole`, `iam:AttachRolePolicy`, `iam:PassRole`
- `sts:AssumeRole`

## Step-by-Step Deployment

### 1. Configure AWS Credentials

```bash
aws configure
# Or use a named profile:
export AWS_PROFILE=your-profile

# Set the account and region for CDK
export CDK_DEFAULT_ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
export CDK_DEFAULT_REGION=us-east-1
```

### 2. Install Dependencies

```bash
cd adm
npm install
```

### 3. Bootstrap CDK (One-Time)

This creates the S3 bucket and IAM roles that CDK uses to deploy assets:

```bash
cd infra
npx cdk bootstrap aws://$CDK_DEFAULT_ACCOUNT/$CDK_DEFAULT_REGION
```

### 4. Deploy the Database Stack

Deploy Aurora first since the API stack depends on it:

```bash
npx cdk deploy Adm-dev-Database
```

This creates:
- VPC with 2 public subnets
- Security group allowing PostgreSQL (port 5432) access
- Aurora Serverless v2 PostgreSQL 16 cluster
- Secrets Manager secret with generated DB credentials

**Note the outputs:**

```
Adm-dev-Database.DbEndpoint = your-cluster.cluster-xxx.us-east-1.rds.amazonaws.com
Adm-dev-Database.DbSecretArn = arn:aws:secretsmanager:us-east-1:xxx:secret:adm/dev/db-credentials-xxx
```

### 5. Seed the Database

Get the DB credentials from Secrets Manager:

```bash
aws secretsmanager get-secret-value \
  --secret-id adm/dev/db-credentials \
  --query SecretString --output text | jq .
```

Connect and run the init scripts:

```bash
# Get the password from the secret above
psql -h <DbEndpoint> -U adm_user -d adm -f db/init/01_adm.sql
psql -h <DbEndpoint> -U adm_user -d adm -f db/init/02_adm_metadata.sql
```

If `psql` is not installed, you can use any PostgreSQL client (DBeaver, pgAdmin, etc.) with the endpoint, username, and password from the secret.

### 6. Deploy the API Stack

```bash
npx cdk deploy Adm-dev-Api
```

This creates:
- 5 Lambda functions (search, expand, update, health, org)
- Lambda Function URLs (direct HTTPS endpoints)
- Secrets Manager secret for LLM API key (placeholder)

**Note the outputs:**

```
Adm-dev-Api.SearchUrl = https://xxx.lambda-url.us-east-1.on.aws/
Adm-dev-Api.ExpandUrl = https://xxx.lambda-url.us-east-1.on.aws/
Adm-dev-Api.UpdateUrl = https://xxx.lambda-url.us-east-1.on.aws/
Adm-dev-Api.OrgUrl = https://xxx.lambda-url.us-east-1.on.aws/
Adm-dev-Api.HealthUrl = https://xxx.lambda-url.us-east-1.on.aws/
Adm-dev-Api.LlmSecretArn = arn:aws:secretsmanager:us-east-1:xxx:secret:adm/dev/llm-api-key-xxx
```

### 7. Set the LLM API Key

The LLM secret is created with a placeholder value. Update it with your actual key:

```bash
aws secretsmanager put-secret-value \
  --secret-id adm/dev/llm-api-key \
  --secret-string '{"apiKey":"your-actual-llm-api-key"}'
```

### 8. Verify the API

```bash
curl https://<HealthUrl>
# {"status":"ok","database":"connected"}

curl -X POST https://<OrgUrl>
# {"nodes":[...],"edges":[...]}
```

### 9. Build and Deploy the Frontend

Create a `.env.production` file with the Lambda Function URLs from step 6:

```bash
cat > frontend/.env.production << 'EOF'
VITE_API_SEARCH_URL=https://xxx.lambda-url.us-east-1.on.aws/
VITE_API_EXPAND_URL=https://xxx.lambda-url.us-east-1.on.aws/
VITE_API_UPDATE_URL=https://xxx.lambda-url.us-east-1.on.aws/
VITE_API_ORG_URL=https://xxx.lambda-url.us-east-1.on.aws/
VITE_API_HEALTH_URL=https://xxx.lambda-url.us-east-1.on.aws/
EOF
```

Build the frontend:

```bash
cd frontend
npm run build
```

Deploy to S3:

```bash
cd ../infra
npx cdk deploy Adm-dev-Frontend
```

**Note the output:**

```
Adm-dev-Frontend.FrontendUrl = http://adm-dev-frontend-xxx.s3-website-us-east-1.amazonaws.com
```

### 10. Open the Application

Open the `FrontendUrl` from the output in your browser.

## Deploy All Stacks at Once

After initial setup, you can deploy everything in one command:

```bash
cd infra
npx cdk deploy --all
```

## Customizing the Deployment

### Change Environment Name

```bash
npx cdk deploy --all -c env=staging
```

This creates separate stacks: `Adm-staging-Database`, `Adm-staging-Api`, `Adm-staging-Frontend`.

### Change LLM Provider

```bash
npx cdk deploy Adm-dev-Api -c llmProvider=anthropic -c llmModel=claude-sonnet-4-6
```

Then update the LLM secret with the corresponding API key.

### Change AWS Region

```bash
export CDK_DEFAULT_REGION=eu-west-1
npx cdk deploy --all
```

## Updating the Application

### Code Changes Only (Lambda)

```bash
cd infra
npx cdk deploy Adm-dev-Api
```

CDK rebundles the Lambda code with esbuild and deploys the updated functions.

### Frontend Changes

```bash
cd frontend
npm run build
cd ../infra
npx cdk deploy Adm-dev-Frontend
```

### Database Schema Changes

Connect to Aurora and run migration scripts manually:

```bash
psql -h <DbEndpoint> -U adm_user -d adm -f db/migrations/your_migration.sql
```

## Tearing Down

To destroy all AWS resources:

```bash
cd infra
npx cdk destroy --all
```

This removes all stacks including the Aurora database. **Data will be lost.**

## Security Considerations

This deployment uses **public RDS access** for simplicity. For production:

1. **Move RDS to private subnets** — add a NAT Gateway ($32/month) so Lambda can reach both RDS and external LLM APIs
2. **Add API authentication** — set `ADM_API_USER` and `ADM_API_PASSWORD` environment variables on the Lambda functions
3. **Restrict Lambda Function URL auth** — change `authType` from `NONE` to `AWS_IAM` and use CloudFront with OAC
4. **Add CloudFront** — in front of both S3 (HTTPS) and Lambda (caching, WAF)
5. **Enable RDS encryption** — already enabled (`storageEncrypted: true`)
6. **Restrict security group** — narrow the `0.0.0.0/0` ingress to specific IP ranges

## Troubleshooting

### CDK Bootstrap Errors

```bash
# If you get permission errors during bootstrap
npx cdk bootstrap --trust $CDK_DEFAULT_ACCOUNT aws://$CDK_DEFAULT_ACCOUNT/$CDK_DEFAULT_REGION
```

### Lambda Cold Start Timeouts

The search and update functions have 60-second timeouts. If cold starts are too slow:

- Increase `memorySize` in `infra/lib/api-stack.ts` (more memory = faster CPU)
- Consider provisioned concurrency for frequently used functions

### Aurora Connection Issues

```bash
# Test connectivity
psql -h <DbEndpoint> -U adm_user -d adm -c "SELECT 1"

# If connection refused, check security group allows your IP
aws ec2 describe-security-groups --group-ids <sg-id>
```

### Frontend Not Loading After Deploy

- Verify the S3 bucket has `index.html`
- Check that `.env.production` had the correct Lambda URLs before building
- Clear browser cache

### LLM API Errors

- Verify the secret has the correct key: `aws secretsmanager get-secret-value --secret-id adm/dev/llm-api-key`
- Check Lambda logs: `aws logs tail /aws/lambda/adm-dev-search --follow`
