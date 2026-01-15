# GitHub Copilot Instructions

This document provides repository-specific guidance for GitHub Copilot usage.

## Tech Stack

- **Language:** Python 3.11
- **Web Framework:** Flask 2.3.2
- **Deployment:** AWS Lambda (container image)
- **Container Runtime:** Docker
- **WSGI Adapter:** aws-serverless-wsgi 0.6.1
- **CI/CD:** GitHub Actions
- **Cloud Services:**
  - Amazon ECR (Elastic Container Registry)
  - AWS Lambda
  - Lambda Function URLs

## MarcoAAlmeida Preferences

### Communication Style
1. **Always use numbered questions** when asking for clarification or presenting options
   - Example: "Would you like to: 1) Add error handling, 2) Update documentation, 3) Both?"

2. **Prefer code examples** over lengthy explanations
   - Show working code snippets instead of abstract descriptions
   - Include inline comments for complex logic

3. **Do NOT invent URLs or endpoints**
   - Never make up AWS endpoints, API URLs, or web addresses
   - Always use placeholders like `YOUR-FUNCTION-URL` or `EXAMPLE.COM` when the actual URL is unknown
   - Reference documentation URLs only if you're certain they exist

### Development Practices

- **Testing:** Include examples of how to test changes locally (Docker, SAM, curl)
- **Documentation:** Keep docs concise but complete; prefer step-by-step instructions
- **Error handling:** Add appropriate try-catch blocks for production code
- **Security:** Never commit secrets; use environment variables or GitHub secrets

## When to Open Pull Requests

Create a PR when:
- Adding new features or functionality
- Making infrastructure or deployment changes
- Updating documentation that affects user workflows
- Refactoring code that changes behavior

Do NOT create a PR for:
- Typo fixes in comments or docs (direct commit to branch is fine)
- Trivial formatting changes
- Local configuration files that don't affect others

## Code Style

- Follow PEP 8 for Python code
- Use type hints where appropriate
- Keep functions small and focused
- Add docstrings for public functions
- Use descriptive variable names (no single letters except for common iterators)

## Common Patterns in This Repository

### Flask Routes
```python
@app.route("/path", methods=["GET", "POST"])
def handler():
    return jsonify(key="value")
```

### Lambda Handler
```python
def lambda_handler(event, context):
    return serverless_wsgi.handle_request(app, event, context)
```

### Docker Best Practices
- Use official AWS Lambda base images
- Install dependencies in separate RUN layers for better caching
- Copy application code last to leverage build cache

## Workflow Patterns

- **Local Development:** Use Docker for consistent environment
- **Testing:** Test locally before pushing (docker build, docker run, curl)
- **Deployment:** Push to `main` triggers automatic deployment via GitHub Actions
- **Secrets:** All AWS credentials and config stored in GitHub secrets

## Repository Structure

```
.
├── app.py                          # Flask application
├── lambda_function.py              # Lambda handler wrapper
├── requirements.txt                # Python dependencies
├── Dockerfile                      # Container image definition
├── .github/
│   ├── workflows/
│   │   └── deploy-image.yml        # CI/CD pipeline
│   └── copilot-instructions.md     # This file
├── docs/
│   └── setup.md                    # AWS and GitHub setup guide
└── README.md                       # Project overview
```

## Helpful Commands

### Local Testing
```bash
# Build image
docker build -t flask-lambda:test .

# Run locally
docker run -p 9000:8080 flask-lambda:test

# Test with curl (Lambda Runtime Interface Emulator)
curl -X POST "http://localhost:9000/2015-03-31/functions/function/invocations" \
  -d '{"httpMethod":"GET","path":"/","headers":{}}'
```

### AWS CLI (for debugging)
```bash
# Check Lambda function
aws lambda get-function --function-name flask-hello-world

# View logs
aws logs tail /aws/lambda/flask-hello-world --follow

# Test function
aws lambda invoke --function-name flask-hello-world response.json
```

## Questions?

If you need to ask the developer for clarification:
1. Use numbered questions
2. Provide code examples showing the proposed change
3. Explain the tradeoffs of different approaches
