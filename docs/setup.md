# AWS Setup Guide

This guide provides step-by-step instructions for setting up AWS resources and GitHub secrets to deploy the Flask Lambda container image.

## Prerequisites

- AWS Account with administrative access
- GitHub repository with Actions enabled
- AWS CLI installed locally (optional, for verification)

## AWS Setup Steps

### 1. Create IAM Policy for Deployment User

Create an IAM policy that grants permissions needed for the GitHub Actions workflow:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecr:GetAuthorizationToken",
        "ecr:CreateRepository",
        "ecr:DescribeRepositories",
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "ecr:PutImage",
        "ecr:InitiateLayerUpload",
        "ecr:UploadLayerPart",
        "ecr:CompleteLayerUpload"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "lambda:CreateFunction",
        "lambda:UpdateFunctionCode",
        "lambda:GetFunction",
        "lambda:CreateFunctionUrlConfig",
        "lambda:GetFunctionUrlConfig",
        "iam:PassRole"
      ],
      "Resource": "*"
    }
  ]
}
```

**Steps:**
1. Go to AWS Console → IAM → Policies
2. Click "Create Policy"
3. Switch to JSON tab and paste the policy above
4. Name it `GitHubActionsLambdaDeploy`
5. Click "Create policy"

### 2. Create IAM User for GitHub Actions

1. Go to AWS Console → IAM → Users
2. Click "Create user"
3. Username: `github-actions-deployer` (or your preference)
4. Click "Next"
5. Attach the `GitHubActionsLambdaDeploy` policy created above
6. Click "Next" and "Create user"

### 3. Create Access Keys for the User

1. Select the newly created user
2. Go to "Security credentials" tab
3. Click "Create access key"
4. Choose "Third-party service" or "Other"
5. Click "Next" and "Create access key"
6. **Save the Access Key ID and Secret Access Key** (you won't see the secret again)

### 4. Create Lambda Execution Role

The Lambda function needs an execution role to run. You can create it via CloudFormation or manually.

#### Option A: Using CloudFormation

Save this template as `lambda-role.yaml`:

```yaml
AWSTemplateFormatVersion: '2010-09-09'
Resources:
  LambdaExecutionRole:
    Type: AWS::IAM::Role
    Properties:
      RoleName: FlaskLambdaExecutionRole
      AssumeRolePolicyDocument:
        Version: '2012-10-17'
        Statement:
          - Effect: Allow
            Principal:
              Service: lambda.amazonaws.com
            Action: sts:AssumeRole
      ManagedPolicyArns:
        - arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole

Outputs:
  LambdaRoleArn:
    Description: ARN of the Lambda execution role
    Value: !GetAtt LambdaExecutionRole.Arn
```

Deploy it:
```bash
aws cloudformation create-stack \
  --stack-name flask-lambda-role \
  --template-body file://lambda-role.yaml \
  --capabilities CAPABILITY_NAMED_IAM

aws cloudformation describe-stacks \
  --stack-name flask-lambda-role \
  --query 'Stacks[0].Outputs[0].OutputValue' \
  --output text
```

Copy the output ARN for GitHub secrets.

#### Option B: Using AWS Console

1. Go to AWS Console → IAM → Roles
2. Click "Create role"
3. Select "AWS service" and "Lambda"
4. Click "Next"
5. Attach policy: `AWSLambdaBasicExecutionRole`
6. Click "Next"
7. Role name: `FlaskLambdaExecutionRole`
8. Click "Create role"
9. Open the role and copy its ARN (format: `arn:aws:iam::ACCOUNT_ID:role/FlaskLambdaExecutionRole`)

## GitHub Secrets Configuration

Add the following secrets to your GitHub repository:

1. Go to your GitHub repository → Settings → Secrets and variables → Actions
2. Click "New repository secret" for each of the following:

| Secret Name | Value | Description |
|-------------|-------|-------------|
| `AWS_ACCESS_KEY_ID` | `AKIA...` | Access key from step 3 above |
| `AWS_SECRET_ACCESS_KEY` | `wJalr...` | Secret key from step 3 above |
| `AWS_REGION` | `us-east-1` | Your preferred AWS region |
| `ECR_ACCOUNT` | `123456789012` | Your AWS account ID (12 digits) |
| `ECR_REPOSITORY` | `flask-lambda-app` | Name for your ECR repository |
| `LAMBDA_FUNCTION_NAME` | `flask-hello-world` | Name for your Lambda function |
| `LAMBDA_ROLE_ARN` | `arn:aws:iam::123456789012:role/FlaskLambdaExecutionRole` | ARN from step 4 above (required only if function doesn't exist) |

**How to find your AWS Account ID:**
```bash
aws sts get-caller-identity --query Account --output text
```
Or in Console: Click your username (top right) → Account ID is displayed

## Triggering the Initial Deployment

Once all secrets are configured:

1. Push a commit to the `main` branch:
   ```bash
   git checkout main
   git merge copilot/seed
   git push origin main
   ```

2. The GitHub Actions workflow will automatically:
   - Build the Docker image
   - Create the ECR repository (if it doesn't exist)
   - Push the image to ECR
   - Create the Lambda function (if it doesn't exist)
   - Create a public Function URL
   - Output the Function URL in the workflow logs

3. Check the Actions tab in your GitHub repository to monitor the deployment

## Testing the Deployment

After the workflow completes:

1. Go to GitHub Actions → View the latest workflow run
2. Open the "Ensure public Function URL exists" step
3. Copy the Function URL (e.g., `https://abc123.lambda-url.us-east-1.on.aws/`)
4. Test it:
   ```bash
   curl https://YOUR-FUNCTION-URL/
   ```
   Expected response: `{"message":"Hello world!"}`

## AWS Cleanup

To remove all resources and avoid charges:

### 1. Delete Lambda Function
```bash
aws lambda delete-function --function-name flask-hello-world
```

### 2. Delete ECR Repository
```bash
aws ecr delete-repository --repository-name flask-lambda-app --force
```

### 3. Delete Lambda Execution Role (if using CloudFormation)
```bash
aws cloudformation delete-stack --stack-name flask-lambda-role
```

### 4. Delete Lambda Execution Role (if created manually)
1. Go to IAM → Roles
2. Find `FlaskLambdaExecutionRole`
3. Click "Delete" and confirm

### 5. Optionally Delete IAM User
1. Go to IAM → Users
2. Find `github-actions-deployer`
3. Delete access keys first, then delete the user

## Troubleshooting

### Workflow fails with "ResourceNotFoundException"
- Ensure `LAMBDA_ROLE_ARN` secret is set correctly
- Verify the role exists in your AWS account

### Workflow fails with "AccessDeniedException"
- Check that the IAM user has the correct policy attached
- Verify AWS credentials in GitHub secrets

### Function URL returns 502 or 503
- Check Lambda logs in CloudWatch Logs
- Verify the Docker image was built correctly
- Test locally using the instructions in README.md

### ECR push fails
- Ensure `ECR_ACCOUNT` matches your AWS account ID
- Verify ECR permissions in the IAM policy

## Next Steps

- Review CloudWatch Logs for your Lambda function
- Add custom routes to your Flask app
- Configure environment variables for the Lambda function
- Add API Gateway for custom domain and advanced routing
- Set up monitoring and alarms in CloudWatch
