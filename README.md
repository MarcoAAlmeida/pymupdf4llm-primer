# Flask Hello World Lambda Container

A minimal Flask "Hello World" application packaged as an AWS Lambda container image, with automated deployment via GitHub Actions.

## Overview

This project demonstrates how to:
- Create a simple Flask REST API
- Package it as a Docker container image compatible with AWS Lambda
- Deploy it automatically to AWS Lambda using GitHub Actions
- Expose the Lambda function via a public Function URL for testing

## Tech Stack

- **Python 3.11** - Runtime environment
- **Flask 2.3.2** - Web framework
- **aws-serverless-wsgi** - Adapter to run Flask in Lambda
- **Docker** - Container packaging
- **AWS Lambda** - Serverless compute
- **Amazon ECR** - Container registry
- **GitHub Actions** - CI/CD pipeline

## API Endpoints

- `GET /` - Returns `{"message": "Hello world!"}`

## Local Development

### Prerequisites

- Docker installed locally
- (Optional) AWS SAM CLI for local Lambda testing

### Run Locally with Docker

Build the Docker image:
```bash
docker build -t flask-lambda:local .
```

Run the container using the Lambda Runtime Interface Emulator (RIE):
```bash
docker run -p 9000:8080 flask-lambda:local
```

Test the endpoint by invoking the Lambda function locally:
```bash
curl -X POST "http://localhost:9000/2015-03-31/functions/function/invocations" \
  -d '{
    "httpMethod": "GET",
    "path": "/",
    "headers": {},
    "body": null
  }'
```

Expected response:
```json
{
  "statusCode": 200,
  "headers": {
    "Content-Type": "application/json"
  },
  "body": "{\"message\":\"Hello world!\"}"
}
```

### Run Locally with AWS SAM

If you have AWS SAM CLI installed, you can test the Lambda function locally:

1. Create a simple `template.yaml` for SAM:
```yaml
AWSTemplateFormatVersion: '2010-09-09'
Transform: AWS::Serverless-2016-10-31

Resources:
  FlaskFunction:
    Type: AWS::Serverless::Function
    Properties:
      PackageType: Image
      ImageUri: flask-lambda:local
      Events:
        ApiEvent:
          Type: HttpApi
          Properties:
            Path: /
            Method: get

Metadata:
  FlaskFunction:
    Dockerfile: Dockerfile
    DockerContext: .
    DockerTag: latest
```

2. Start the local API:
```bash
sam local start-api
```

3. Test the endpoint:
```bash
curl http://localhost:3000/
```

Expected response:
```json
{"message": "Hello world!"}
```

## Deployment

### Prerequisites

1. AWS account with appropriate permissions
2. GitHub repository with Actions enabled
3. Required GitHub secrets configured (see [docs/setup.md](docs/setup.md))

### Deployment Process

Deployments are automated via GitHub Actions:

1. Push to the `main` branch:
   ```bash
   git push origin main
   ```

2. The workflow automatically:
   - Builds the Docker image
   - Creates ECR repository (if needed)
   - Pushes the image to Amazon ECR
   - Creates/updates the Lambda function
   - Creates a public Function URL (if needed)
   - Outputs the Function URL in the logs

3. Monitor the deployment in the GitHub Actions tab

### Testing the Deployed Function

After deployment, find the Function URL in the GitHub Actions workflow logs or run:

```bash
aws lambda get-function-url-config \
  --function-name flask-hello-world \
  --query FunctionUrl \
  --output text
```

Test it:
```bash
curl https://YOUR-FUNCTION-URL/
```

Expected response:
```json
{"message": "Hello world!"}
```

## Project Structure

```
.
├── app.py                          # Flask application
├── lambda_function.py              # Lambda handler wrapper
├── requirements.txt                # Python dependencies
├── Dockerfile                      # Container image definition
├── .github/
│   ├── workflows/
│   │   └── deploy-image.yml        # CI/CD pipeline
│   └── copilot-instructions.md     # Copilot guidance
├── docs/
│   └── setup.md                    # AWS and GitHub setup guide
└── README.md                       # This file
```

## Configuration

All AWS configuration is managed via GitHub secrets. See [docs/setup.md](docs/setup.md) for detailed setup instructions.

Required secrets:
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `AWS_REGION`
- `ECR_ACCOUNT`
- `ECR_REPOSITORY`
- `LAMBDA_FUNCTION_NAME`
- `LAMBDA_ROLE_ARN` (required only if creating new function)

## Development Workflow

1. Make changes to `app.py` or other files
2. Test locally using Docker (see above)
3. Commit and push to a feature branch
4. Create a pull request to `main`
5. After merge, GitHub Actions deploys automatically

## Cleanup

To remove all AWS resources:

```bash
# Delete Lambda function
aws lambda delete-function --function-name flask-hello-world

# Delete ECR repository
aws ecr delete-repository --repository-name flask-lambda-app --force

# Delete Lambda execution role (if created via CloudFormation)
aws cloudformation delete-stack --stack-name flask-lambda-role
```

See [docs/setup.md](docs/setup.md) for detailed cleanup instructions.

## Troubleshooting

### Local Docker Issues

**Container fails to start:**
- Check Docker logs: `docker logs CONTAINER_ID`
- Verify dependencies installed: `docker run -it flask-lambda:local /bin/bash`

**Port already in use:**
- Use a different port: `docker run -p 9001:8080 flask-lambda:local`

### Deployment Issues

**Workflow fails:**
- Check GitHub Actions logs for specific errors
- Verify all secrets are set correctly
- Ensure IAM permissions are configured properly

**502/503 errors from Function URL:**
- Check Lambda CloudWatch logs
- Verify the Docker image includes all dependencies
- Test the image locally first

See [docs/setup.md](docs/setup.md) for more troubleshooting tips.

## License

See [LICENSE](LICENSE) file.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test locally
5. Submit a pull request

## Additional Resources

- [AWS Lambda Container Images](https://docs.aws.amazon.com/lambda/latest/dg/images-create.html)
- [Flask Documentation](https://flask.palletsprojects.com/)
- [aws-serverless-wsgi](https://github.com/logandk/serverless-wsgi)
- [GitHub Actions for AWS](https://github.com/aws-actions)
